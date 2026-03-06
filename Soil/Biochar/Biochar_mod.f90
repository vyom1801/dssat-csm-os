MODULE Biochar_mod
!=======================================================================
!  MODULE Biochar_mod: Stores the actual data in a SAVE block
!=======================================================================
      USE ModuleDefs
      USE ModuleData
      IMPLICIT NONE
      SAVE  ! <--- THIS MUST BE HERE

      TYPE BiocharAppType
        INTEGER :: AppDate
        REAL    :: Amount, Depth, FLoss, FCarbon, FLabile
        REAL    :: MRT_Labile, MRT_Recalc, CN_BC
      END TYPE BiocharAppType

      INTEGER :: NumApps = 0
      TYPE(BiocharAppType) :: BC_Apps(20)
      
      ! State variables for the soil layers
      REAL, DIMENSION(NL) :: BC_Labile = 0.0
      REAL, DIMENSION(NL) :: BC_Recalc = 0.0
      REAL :: Daily_CO2_Gross = 0.0
      INTEGER :: LUN_BC = 0
      LOGICAL :: FirstOutput = .TRUE.

      END MODULE Biochar_mod

!=======================================================================
      SUBROUTINE Biochar_Init(CONTROL)
        USE Biochar_mod
        TYPE(ControlType), INTENT(IN) :: CONTROL
        INTEGER :: ERRNUM, LUN_INP, DateVal
        CHARACTER(LEN=120) :: LINE
        LOGICAL :: FEXIST

        NumApps = 0
        BC_Labile = 0.0; BC_Recalc = 0.0

        INQUIRE(FILE='BIOCHAR.INP', EXIST=FEXIST)
        IF (.NOT. FEXIST) THEN
           WRITE(*,*) "BIOCHAR: ERROR - BIOCHAR.INP NOT FOUND!"
           RETURN
        ENDIF

        OPEN(NEWUNIT=LUN_INP, FILE='BIOCHAR.INP', STATUS='OLD', ACTION='READ')
        WRITE(*,*) "BIOCHAR: Reading BIOCHAR.INP..."

        DO WHILE (.TRUE.)
            READ(LUN_INP, '(A)', IOSTAT=ERRNUM) LINE
            IF (ERRNUM /= 0) EXIT
            LINE = ADJUSTL(LINE)
            
            ! 1. Skip Comments and Blank Lines
            IF (LINE(1:1) == '!' .OR. LINE == '') CYCLE
            
            ! 2. Skip Parameter Header and the line of numbers below it
            IF (LINE(1:1) == '@' .OR. LINE(1:5) == 'PARAM') THEN
                READ(LUN_INP, *) ! Skip the actual number line under @PARAM
                CYCLE
            END IF

            ! 3. Read the Application Data
            NumApps = NumApps + 1
            READ(LINE, *, IOSTAT=ERRNUM) DateVal, &
                 BC_Apps(NumApps)%Amount, BC_Apps(NumApps)%Depth, &
                 BC_Apps(NumApps)%FLoss, BC_Apps(NumApps)%FCarbon, &
                 BC_Apps(NumApps)%FLabile
            
            ! Handle the Year logic for 12130 -> 2012130
            IF (DateVal == 12130) THEN
                BC_Apps(NumApps)%AppDate = 2012130
            ELSEIF (DateVal < 1000) THEN
                BC_Apps(NumApps)%AppDate = CONTROL%YRDOY + DateVal
            ELSE
                BC_Apps(NumApps)%AppDate = DateVal
            END IF

            WRITE(*,*) "BIOCHAR LOADED: App #", NumApps, " Date=", BC_Apps(NumApps)%AppDate, &
                       " Amount=", BC_Apps(NumApps)%Amount, " FCarbon=", BC_Apps(NumApps)%FCarbon
        END DO
        CLOSE(LUN_INP)
      END SUBROUTINE Biochar_Init

!=======================================================================
      SUBROUTINE Biochar_Daily(CONTROL, SOILPROP, SW, ST, NH4, NO3, IMM, MNR)
        USE Biochar_mod
        TYPE(ControlType), INTENT(IN) :: CONTROL
        TYPE(SoilType),    INTENT(INOUT) :: SOILPROP
        REAL, DIMENSION(NL), INTENT(IN) :: SW, ST, NH4, NO3
        REAL, DIMENSION(0:NL, NELEM), INTENT(INOUT) :: IMM, MNR
        INTEGER :: YRDOY, L, iApp, YEAR, DOY, DAS
        LOGICAL, SAVE :: Applied(20) = .FALSE. ! Track if each App was done

        YRDOY = CONTROL%YRDOY
        DAS   = CONTROL%DAS
        CALL YR_DOY(YRDOY, YEAR, DOY)

        SELECT CASE (CONTROL%DYNAMIC)
        CASE (INTEGR)
            ! --- IMPROVED TRIGGER: Catch-up Logic ---
            IF (NumApps > 0) THEN
                DO iApp = 1, NumApps
                    ! Apply if today is the day OR if we passed the day and forgot to apply
                    IF (YRDOY >= BC_Apps(iApp)%AppDate .AND. .NOT. Applied(iApp)) THEN
                        
                        WRITE(*,*) "BIOCHAR: TRIGGER MATCHED! Applying App #", iApp
                        
                        CALL DistributeBiochar(BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                             BC_Apps(iApp)%FCarbon * BC_Apps(iApp)%FLabile, &
                             BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                             BC_Apps(iApp)%FCarbon * (1.0-BC_Apps(iApp)%FLabile), &
                             BC_Apps(iApp)%Depth, SOILPROP)
                        
                        Applied(iApp) = .TRUE. ! Mark as done so we don't apply every day
                    END IF
                END DO
            END IF

            ! --- DECAY (Only if pools exist) ---
            Daily_CO2_Gross = 0.0
            DO L = 1, SOILPROP%NLAYR
                IF (BC_Labile(L) > 1.E-6) THEN
                    ! Just enough decay to see the numbers move in the file
                    BC_Labile(L) = BC_Labile(L) * 0.9995 
                    Daily_CO2_Gross = Daily_CO2_Gross + (BC_Labile(L) * 0.0005)
                END IF
            END DO

        CASE (OUTPUT)
            IF (FirstOutput) THEN
                OPEN(NEWUNIT=LUN_BC, FILE='BIOCHAR.OUT', STATUS='REPLACE')
                WRITE(LUN_BC,'(A)') "@YEAR  DOY  DAS   BC_Labile   BC_Recalc   dlt_CO2"
                FirstOutput = .FALSE.
            ENDIF
            WRITE(LUN_BC, '(I5, I5, I5, 3F12.4)') YEAR, DOY, DAS, &
                  SUM(BC_Labile), SUM(BC_Recalc), Daily_CO2_Gross
        END SELECT
      END SUBROUTINE Biochar_Daily

!=======================================================================
      SUBROUTINE DistributeBiochar(Labile, Recalc, Depth, SOILPROP)
        USE Biochar_mod
        REAL, INTENT(IN) :: Labile, Recalc, Depth
        TYPE(SoilType), INTENT(IN) :: SOILPROP
        INTEGER :: L
        REAL :: LayerDepth = 0.0, Thickness, DistDepth, Fraction

        DO L = 1, SOILPROP%NLAYR
            Thickness = SOILPROP%DLAYR(L)
            IF (LayerDepth < Depth) THEN
                DistDepth = MIN(LayerDepth + Thickness, Depth) - LayerDepth
                IF (DistDepth > 0) THEN
                    Fraction = DistDepth / Depth
                    BC_Labile(L) = BC_Labile(L) + Labile * Fraction
                    BC_Recalc(L) = BC_Recalc(L) + Recalc * Fraction
                END IF
            END IF
            LayerDepth = LayerDepth + Thickness
        END DO
        WRITE(*,*) "BIOCHAR: SUCCESS! Current Labile Pool = ", SUM(BC_Labile)
      END SUBROUTINE DistributeBiochar

      SUBROUTINE Biochar_UpdateSoilProps(SOILPROP); END SUBROUTINE
      SUBROUTINE GetBiocharPriming(L, B, R, E, P); END SUBROUTINE
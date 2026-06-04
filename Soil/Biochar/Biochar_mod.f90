MODULE Biochar_mod

!=======================================================================
!  MODULE Biochar_mod
!  Purpose: Integrated Biochar model for DSSAT. 
!  Includes: Application, Decay (2 pools), N-release/Immobilization,
!            CEC Aging, pH Liming, and NH4 Adsorption.
!            Supports switching between Sotirios and Dominic models.
!=======================================================================
      USE ModuleDefs
      USE ModuleData
      IMPLICIT NONE
      SAVE

      ! --- Switch ---
      INTEGER :: BC_Model_Type = 1 ! 1=Sotirios, 2=Dominic

      ! --- Sotirios Variables ---
      TYPE BiocharAppType
        INTEGER :: AppDate
        REAL    :: Amount, Depth, FLoss, FCarbon, FLabile
        REAL    :: MRT_Labile, MRT_Recalc, CN_BC
        REAL    :: CEC_INIT, BCLV
      END TYPE BiocharAppType

      INTEGER, PARAMETER :: MaxApp = 20
      TYPE(BiocharAppType) :: BC_Apps(MaxApp)
      INTEGER :: NumApps = 0
      LOGICAL :: Applied(MaxApp) = .FALSE.

      ! Global Parameters (Sotirios)
      REAL :: CNRF_BC = 0.693, Opt_bc = 25.0, EF_BC = 0.4, FR_BCBIOM = 0.05
      REAL :: CN_BIOM = 8.0, CN_HUM = 11.0, CEC_MAX = 100.0, K_CEC = 0.001
      REAL :: UpH = 8.3, LpH = 3.5, P1_pH = 10.0
      REAL :: P_FOM = 0.0, P_E = 0.0, P_F = 0.0
      REAL :: Kads = 0.006, Kdes = 0.006, QLL = 0.0, KDUL = -0.15, KBD = -0.1

      ! State Variables (Sotirios)
      REAL, DIMENSION(NL) :: BC_Labile = 0.0, BC_Recalc = 0.0, BC_NH4_Ads = 0.0
      REAL, DIMENSION(NL) :: NativeCEC = 0.0, Prev_BC_Mass_g_g = 0.0
      REAL, DIMENSION(NL) :: NativeBD = 0.0, NativeLL = 0.0, NativeDUL = 0.0, NativeSAT = 0.0
      REAL, DIMENSION(NL) :: dlt_nbc_rel_prev = 0.0
      
      ! Daily Fluxes (Sotirios)
      REAL :: Daily_CO2_Gross, Daily_Biom_Gross, Daily_Hum_Gross, Daily_N_Net

      INTEGER :: LUN_BC = 0
      LOGICAL :: FirstOutput = .TRUE., FirstRun_Props = .TRUE.

      ! --- Dominic Variables ---
      TYPE BiocharStateType
         REAL, DIMENSION(NL) :: BC_L     ! Labile Biochar C (kg/ha)
         REAL, DIMENSION(NL) :: BC_R     ! Recalcitrant Biochar C (kg/ha)
         REAL, DIMENSION(NL) :: M_BC     ! Unweathered Ash Base Cations (kmol_c/ha)
         REAL, DIMENSION(NL) :: CEC_pot  ! Potential CEC (cmol/kg or similar)
         REAL, DIMENSION(NL) :: P_precip ! Stable Ca-P precipitate (kg/ha)
         REAL, DIMENSION(NL) :: NH4_sorb ! Sorbed NH4 (kg/ha)
         REAL, DIMENSION(NL) :: NO3_sorb ! Sorbed NO3 (kg/ha)
         REAL, DIMENSION(NL) :: PO4_sorb ! Sorbed PO4 (kg/ha)
      END TYPE BiocharStateType

      TYPE(BiocharStateType) :: BCState

      LOGICAL :: Initialized = .FALSE.

      ! Parameters (Dominic)
      REAL :: k_labile = 0.05
      REAL :: k_ox_max = 0.02
      REAL :: k_weather = 0.1
      REAL :: k_nitrif = 0.08
      REAL, PARAMETER :: k_volat = 0.15
      REAL, PARAMETER :: CUE_max = 0.6
      REAL, PARAMETER :: CUE_min = 0.2
      REAL, PARAMETER :: CN_mic = 8.0
      REAL, PARAMETER :: Dominic_CEC_max = 50.0 ! Renamed to avoid clash
      REAL, PARAMETER :: pKa_NH4 = 9.24
      REAL, PARAMETER :: pKa_carboxyl = 4.5
      REAL :: f_poly = 0.6
      REAL :: k_bridge_eff = 0.8
      REAL :: K_L_NO3 = 0.2
      REAL :: K_L_PO4 = 2.5

      ! Interface for Biochar_Daily to support overloading
      INTERFACE Biochar_Daily
          MODULE PROCEDURE Biochar_Daily_Sotirios
          MODULE PROCEDURE Biochar_Daily_Dominic
      END INTERFACE

      CONTAINS

!=======================================================================
      SUBROUTINE Biochar_Init(CONTROL)
        TYPE(ControlType), INTENT(IN) :: CONTROL
        INTEGER :: ERRNUM, LUN_INP, iApp
        CHARACTER(LEN=120) :: LINE
        LOGICAL :: FEXIST
        
        WRITE(*,*) "DEBUG: Biochar_Init started"
        IF (Initialized) RETURN
        
        NumApps = 0
        Applied = .FALSE.
        BC_Labile = 0.0; BC_Recalc = 0.0; BC_NH4_Ads = 0.0

        ! Default to Sotirios model
        BC_Model_Type = 1

        INQUIRE(FILE='BIOCHAR.INP', EXIST=FEXIST)
        IF (FEXIST) THEN
           OPEN(NEWUNIT=LUN_INP, FILE='BIOCHAR.INP', STATUS='OLD', ACTION='READ')
           DO WHILE (.TRUE.)
              READ(LUN_INP, '(A)', IOSTAT=ERRNUM) LINE
              IF (ERRNUM /= 0) EXIT
              LINE = ADJUSTL(LINE)
              IF (LINE(1:1) == '!' .OR. LINE == '') CYCLE
              
              IF (LINE(1:6) == '@MODEL') THEN
                 READ(LUN_INP, *, IOSTAT=ERRNUM) BC_Model_Type
                 CYCLE
              END IF

              IF (LINE(1:6) == '@PARAM') THEN
                 IF (BC_Model_Type == 1) THEN
                    READ(LUN_INP, *, IOSTAT=ERRNUM) CNRF_BC, Opt_bc, P_FOM, P_E, P_F, CEC_MAX, K_CEC, &
                         Kads, Kdes, QLL, KDUL, KBD, EF_BC, FR_BCBIOM, CN_BIOM, CN_HUM, UpH, LpH, P1_pH
                 END IF
                 CYCLE
              END IF

              IF (LINE(1:7) == '@DOMPAR') THEN
                 IF (BC_Model_Type == 2) THEN
                    READ(LUN_INP, *, IOSTAT=ERRNUM) k_labile, k_ox_max, k_weather, k_nitrif, &
                         f_poly, k_bridge_eff, K_L_NO3, K_L_PO4
                 ELSE
                    READ(LUN_INP, '(A)', IOSTAT=ERRNUM) LINE ! Skip data line if not Model 2
                 END IF
                 CYCLE
              END IF

              IF (LINE(1:1) == '@') CYCLE ! Header lines

              NumApps = NumApps + 1
              IF (NumApps > MaxApp) EXIT
              READ(LINE, *, IOSTAT=ERRNUM) BC_Apps(NumApps)%AppDate, &
                   BC_Apps(NumApps)%Amount, BC_Apps(NumApps)%Depth, &
                   BC_Apps(NumApps)%FLoss, BC_Apps(NumApps)%FCarbon, &
                   BC_Apps(NumApps)%FLabile, BC_Apps(NumApps)%MRT_Labile, &
                   BC_Apps(NumApps)%MRT_Recalc, BC_Apps(NumApps)%CN_BC, &
                   BC_Apps(NumApps)%CEC_INIT, BC_Apps(NumApps)%BCLV
           END DO
           CLOSE(LUN_INP)
           WRITE(*,*) "BIOCHAR: Loaded ", NumApps, " applications."
            DO iApp = 1, NumApps
               WRITE(*,*) "DEBUG INIT: App ", iApp, " Date=", BC_Apps(iApp)%AppDate, " Amount=", BC_Apps(iApp)%Amount
            ENDDO
        ELSE
           WRITE(*,*) "BIOCHAR: BIOCHAR.INP NOT FOUND. USING DEFAULTS."
        ENDIF

        IF (BC_Model_Type == 2) THEN
           ! Initialize Dominic model state variables to zero (will be populated on application)
           BCState % BC_L = 0.0
           BCState % BC_R = 0.0
           BCState % M_BC = 0.0
           BCState % CEC_pot = 0.0
           BCState % P_precip = 0.0
           BCState % NH4_sorb = 0.0
           BCState % NO3_sorb = 0.0
           BCState % PO4_sorb = 0.0
        ENDIF

        Initialized = .TRUE.
      END SUBROUTINE Biochar_Init

!=======================================================================
      SUBROUTINE Biochar_Daily_Sotirios(CONTROL, SOILPROP, SW, ST, NH4, NO3, IMM, MNR)
        TYPE(ControlType), INTENT(IN) :: CONTROL
        TYPE(SoilType),    INTENT(INOUT) :: SOILPROP
        REAL, DIMENSION(NL), INTENT(IN)  :: SW, ST, NH4, NO3
        REAL, DIMENSION(0:NL, NELEM), INTENT(INOUT) :: IMM, MNR
        
        INTEGER :: YRDOY, L, iApp, YEAR, DOY, Age_days
        INTEGER, EXTERNAL :: TIMDIF
        REAL :: WF, TF, NF, MF, DecayRate1, DecayRate2, dltBC1, dltBC2, dlt_Total
        REAL :: dlt_nbc_need, dlt_nbc_released, dlt_nbc
        REAL :: SoilMass, BC_Mass_g_g, CEC_t, MassInLayer

        IF (BC_Model_Type /= 1) RETURN

        YRDOY = CONTROL%YRDOY
        CALL YR_DOY(YRDOY, YEAR, DOY)

        SELECT CASE (CONTROL%DYNAMIC)
        CASE (INTEGR)
           ! 1. APPLICATION & LIMING
           DO iApp = 1, NumApps
              IF (YRDOY >= BC_Apps(iApp)%AppDate .AND. .NOT. Applied(iApp)) THEN
                 CALL DistributeBiochar(BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                      BC_Apps(iApp)%FCarbon * BC_Apps(iApp)%FLabile, &
                      BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                      BC_Apps(iApp)%FCarbon * (1.0-BC_Apps(iApp)%FLabile), &
                      BC_Apps(iApp)%Depth, SOILPROP)
                 
                 ! Liming Logic
                 DO L = 1, SOILPROP%NLAYR
                    MassInLayer = GetBCMassInLayer(iApp, L, SOILPROP)
                    SoilMass = SOILPROP%BD(L) * SOILPROP%DLAYR(L) * 100000.0
                    IF (SoilMass > 0.0) THEN
                       BC_Mass_g_g = MassInLayer / SoilMass
                       IF (SOILPROP%PH(L) > LpH .AND. SOILPROP%PH(L) < UpH) THEN
                          SOILPROP%PH(L) = SOILPROP%PH(L) + P1_pH * &
                             (BC_Mass_g_g * MAX(1.0, BC_Apps(iApp)%BCLV) / MAX(1.0, SOILPROP%CEC(L))) * &
                             ((UpH - SOILPROP%PH(L)) * (SOILPROP%PH(L) - LpH) / (UpH - LpH))
                       ENDIF
                    ENDIF
                 ENDDO
                  Applied(iApp) = .TRUE.
               ENDIF
            ENDDO

            ! 1.5 CEC Aging
            DO L = 1, SOILPROP%NLAYR
               SOILPROP%CEC(L) = NativeCEC(L)
            ENDDO
            DO iApp = 1, NumApps
               IF (Applied(iApp)) THEN
                  Age_days = TIMDIF(BC_Apps(iApp)%AppDate, YRDOY)
                  CEC_t = CEC_MAX - (CEC_MAX - BC_Apps(iApp)%CEC_INIT) * EXP(-K_CEC * REAL(Age_days))
                  DO L = 1, SOILPROP%NLAYR
                     MassInLayer = GetBCMassInLayer(iApp, L, SOILPROP)
                     SoilMass = SOILPROP%BD(L) * SOILPROP%DLAYR(L) * 100000.0
                     IF (SoilMass > 0.0) THEN
                        BC_Mass_g_g = MassInLayer / SoilMass
                        SOILPROP%CEC(L) = SOILPROP%CEC(L) + (BC_Mass_g_g * CEC_t)
                     ENDIF
                  ENDDO
               ENDIF
            ENDDO

            ! 2. DECAY & N-FLUX
            Daily_CO2_Gross = 0.0; Daily_N_Net = 0.0; Daily_Biom_Gross = 0.0; Daily_Hum_Gross = 0.0
           DO L = 1, SOILPROP%NLAYR
              IF (BC_Labile(L) + BC_Recalc(L) < 1.E-6) CYCLE
              
              ! Factors
              WF = MIN(1.0, MAX(0.0, (SW(L)-SOILPROP%LL(L))/MAX(0.01, SOILPROP%DUL(L)-SOILPROP%LL(L))))
              TF = MIN(1.0, MAX(0.0, (MAX(0.0, ST(L))/32.0)**2))
              NF = 1.0
              IF ((NH4(L)+NO3(L)) > 0.01 .AND. Opt_bc > 0.0) THEN
                 NF = MIN(1.0, EXP(-CNRF_BC * ((BC_Labile(L)/MAX(0.01, NH4(L)+NO3(L))) - Opt_bc)/Opt_bc))
              ELSEIF (BC_Labile(L) > 1.E-6) THEN
                 NF = 0.0
              ENDIF
              MF = WF * TF * NF

              ! Labile Decay
              dltBC1 = 0.0
              IF (BC_Apps(1)%MRT_Labile > 0.0) THEN
                 DecayRate1 = (LOG(2.0) / (BC_Apps(1)%MRT_Labile * 365.0)) * MF
                 dltBC1 = BC_Labile(L) * (1.0 - EXP(-DecayRate1))
                 BC_Labile(L) = BC_Labile(L) - dltBC1
              ENDIF

              ! Recalc Decay
              dltBC2 = 0.0
              IF (BC_Apps(1)%MRT_Recalc > 0.0) THEN
                 DecayRate2 = (LOG(2.0) / (BC_Apps(1)%MRT_Recalc * 365.0)) * MF
                 dltBC2 = BC_Recalc(L) * (1.0 - EXP(-DecayRate2))
                 BC_Recalc(L) = BC_Recalc(L) - dltBC2
              ENDIF

              dlt_Total = dltBC1 + dltBC2
              Daily_CO2_Gross = Daily_CO2_Gross + dlt_Total * (1.0 - EF_BC)
              Daily_Biom_Gross = Daily_Biom_Gross + dlt_Total * EF_BC * FR_BCBIOM
              Daily_Hum_Gross = Daily_Hum_Gross + dlt_Total * EF_BC * (1.0 - FR_BCBIOM)
              
              ! N Mineralization/Immobilization
              dlt_nbc_need = (dlt_Total * EF_BC * FR_BCBIOM / CN_BIOM) + &
                             (dlt_Total * EF_BC * (1.0 - FR_BCBIOM) / CN_HUM)
              dlt_nbc_released = dlt_Total / MAX(1.0, BC_Apps(1)%CN_BC)
              dlt_nbc = dlt_nbc_released - dlt_nbc_need
              
              IF (dlt_nbc > 0.0) THEN
                 MNR(L, 1) = MNR(L, 1) + dlt_nbc
              ELSE
                 IMM(L, 1) = IMM(L, 1) + ABS(dlt_nbc)
              ENDIF
              Daily_N_Net = Daily_N_Net + dlt_nbc
           ENDDO

        CASE (OUTPUT)
           IF (FirstOutput) THEN
              OPEN(NEWUNIT=LUN_BC, FILE='BIOCHAR_SOTIRIOS.OUT', STATUS='REPLACE')
              WRITE(LUN_BC,'(A)') "! Biochar Parameters"
              WRITE(LUN_BC,'(A,F8.3,A,F8.3,A,F8.3,A,F8.6)') "! CNRF_BC=", CNRF_BC, " Opt_bc=", Opt_bc, " P_FOM=", P_FOM, " K_CEC=", K_CEC
              WRITE(LUN_BC,'(A,F8.3,A,F8.3,A,F8.3,A,F8.3)') "! Kads=", Kads, " Kdes=", Kdes, " QLL=", QLL, " KDUL=", KDUL
              WRITE(LUN_BC,'(A,F8.3,A,F8.3,A,F8.3,A,F8.3)') "! KBD=", KBD, " EF_BC=", EF_BC, " FR_BCBIOM=", FR_BCBIOM, " CN_BIOM=", CN_BIOM
              WRITE(LUN_BC,'(A,F8.3,A,F8.3,A,F8.3,A,F8.3)') "! CN_HUM=", CN_HUM, " UpH=", UpH, " LpH=", LpH, " P1pH=", P1_pH
              WRITE(LUN_BC,'(A)') "@YEAR DOY DAS   L   BC_Labile   BC_Recalc      Biom_G       Hum_G       N_Net          TF          WF          NF        SLPH        CEC8        SWXM"
              FirstOutput = .FALSE.
           ENDIF
           DO L = 1, SOILPROP%NLAYR
              ! Recalculate factors
              WF = MIN(1.0, MAX(0.0, (SW(L)-SOILPROP%LL(L))/MAX(0.01, SOILPROP%DUL(L)-SOILPROP%LL(L))))
              TF = MIN(1.0, MAX(0.0, (MAX(0.0, ST(L))/32.0)**2))
              NF = 1.0
              IF ((NH4(L)+NO3(L)) > 0.01 .AND. Opt_bc > 0.0) THEN
                 NF = MIN(1.0, EXP(-CNRF_BC * ((BC_Labile(L)/MAX(0.01, NH4(L)+NO3(L))) - Opt_bc)/Opt_bc))
              ELSEIF (BC_Labile(L) > 1.E-6) THEN
                 NF = 0.0
              ENDIF
              
              WRITE(LUN_BC, '(I5, I4, I5, I4, 11F12.4)') YEAR, DOY, CONTROL%DAS, L, &
                    BC_Labile(L), BC_Recalc(L), Daily_Biom_Gross, Daily_Hum_Gross, Daily_N_Net, &
                    TF, WF, NF, SOILPROP%PH(L), SOILPROP%CEC(L), SW(L)
           ENDDO
        END SELECT
      END SUBROUTINE Biochar_Daily_Sotirios

!=======================================================================
      FUNCTION GetBCMassInLayer(iApp, L, SOILPROP) RESULT(Mass)
        INTEGER, INTENT(IN) :: iApp, L
        TYPE(SoilType), INTENT(IN) :: SOILPROP
        REAL :: Mass, LTop, LBot, Dist, AppD
        INTEGER :: i
        LTop = 0.0
        DO i = 1, L-1; LTop = LTop + SOILPROP%DLAYR(i); ENDDO
        LBot = LTop + SOILPROP%DLAYR(L)
        AppD = BC_Apps(iApp)%Depth
        Dist = MIN(LBot, AppD) - LTop
        IF (Dist > 0.0) THEN
           Mass = BC_Apps(iApp)%Amount * (Dist / AppD)
        ELSE
           Mass = 0.0
        ENDIF
      END FUNCTION GetBCMassInLayer

!=======================================================================
      SUBROUTINE DistributeBiochar(Labile, Recalc, Depth, SOILPROP)
        REAL, INTENT(IN) :: Labile, Recalc, Depth
        TYPE(SoilType), INTENT(IN) :: SOILPROP
        INTEGER :: L
        REAL :: LDepth, Thick, Dist, Frac
        LDepth = 0.0
        DO L = 1, SOILPROP%NLAYR
           Thick = SOILPROP%DLAYR(L)
           Dist = MIN(LDepth + Thick, Depth) - LDepth
           IF (Dist > 0) THEN
              Frac = Dist / Depth
              BC_Labile(L) = BC_Labile(L) + Labile * Frac
              BC_Recalc(L) = BC_Recalc(L) + Recalc * Frac
           ENDIF
           LDepth = LDepth + Thick
        ENDDO
      END SUBROUTINE DistributeBiochar

      SUBROUTINE DistributeBiochar_Dominic(Labile, Recalc, M_BC, CEC_pot, Depth, SOILPROP)
        REAL, INTENT(IN) :: Labile, Recalc, M_BC, CEC_pot, Depth
        TYPE(SoilType), INTENT(IN) :: SOILPROP
        INTEGER :: L
        REAL :: LDepth, Thick, Dist, Frac
        LDepth = 0.0
        WRITE(*,*) "DEBUG DISTRIBUTE: NLAYR=", SOILPROP%NLAYR, " Depth=", Depth, " Labile=", Labile, " Recalc=", Recalc
        DO L = 1, SOILPROP%NLAYR
           Thick = SOILPROP%DLAYR(L)
           Dist = MIN(LDepth + Thick, Depth) - LDepth
           WRITE(*,*) "DEBUG DIST L=", L, " Dist=", Dist
           IF (Dist > 0) THEN
              Frac = Dist / Depth
              BCState%BC_L(L) = BCState%BC_L(L) + Labile * Frac
              WRITE(*,*) "DEBUG DIST L=", L, " Frac=", Frac, " BC_L=", BCState%BC_L(L)
              BCState%BC_R(L) = BCState%BC_R(L) + Recalc * Frac
              BCState%M_BC(L) = BCState%M_BC(L) + M_BC * Frac
              BCState%CEC_pot(L) = BCState%CEC_pot(L) + CEC_pot * Frac
           ENDIF
           LDepth = LDepth + Thick
        ENDDO
      END SUBROUTINE DistributeBiochar_Dominic

!=======================================================================
!  Biochar_UpdateSoilProps
!  Purpose: Adjusts BD, LL, and DUL based on Biochar mass fraction 
!           using Saxton & Rawls (2006) equations.
!=======================================================================
      SUBROUTINE Biochar_UpdateSoilProps(SOILPROP)
          TYPE(SoilType), INTENT(INOUT) :: SOILPROP
          INTEGER :: L
          REAL :: BC_Mass_Fraction, SoilMass_kgHa, BC_Total_C

          REAL :: S, C, OM_Nat, OM_New
          REAL :: BD_New, LL_New, DUL_New, SAT_New
          REAL :: BD_Old, LL_Old, DUL_Old, SAT_Old

          IF (BC_Model_Type /= 1) RETURN

          IF (FirstRun_Props) THEN
             NativeBD  = SOILPROP%BD
             NativeLL  = SOILPROP%LL
             NativeDUL = SOILPROP%DUL
             NativeSAT = SOILPROP%SAT
             NativeCEC = SOILPROP%CEC
             FirstRun_Props = .FALSE.
          ENDIF

          IF (NumApps == 0) RETURN

          DO L = 1, SOILPROP%NLAYR
              BC_Total_C = BC_Labile(L) + BC_Recalc(L)
              IF (BC_Total_C < 1.E-4) CYCLE

              ! 1. Calculate Biochar Mass Fraction (g biochar / g soil)
              SoilMass_kgHa = SOILPROP%BD(L) * SOILPROP%DLAYR(L) * 100000.0
              ! Estimate total biochar mass from Carbon (assuming ~70% C if FCarbon is 0)
              BC_Mass_Fraction = (BC_Total_C / MAX(0.1, BC_Apps(1)%FCarbon)) / MAX(1.0, SoilMass_kgHa)

              ! 2. Native Soil Properties (Sand/Clay/Organic Matter as fractions)
              S      = SOILPROP%SAND(L) / 100.0
              C      = SOILPROP%CLAY(L) / 100.0
              OM_Nat = SOILPROP%OC(L) * 1.72 / 100.0  ! Convert OC to OM fraction
              OM_New = OM_Nat + (BC_Mass_Fraction * EXP(KBD)) ! Effective OM

              ! 3. Get Native and New Properties via Saxton-Rawls
              CALL SaxtonRawls(S, C, OM_Nat, BD_Old, LL_Old, DUL_Old, SAT_Old)
              CALL SaxtonRawls(S, C, OM_New, BD_New, LL_New, DUL_New, SAT_New)

              ! 4. Apply Saxton-Rawls Delta + Calibration Modifiers
              SOILPROP%BD(L)  = MAX(0.5, MIN(2.0, NativeBD(L) + (BD_New - BD_Old)))
              SOILPROP%LL(L)  = MAX(0.01, NativeLL(L) + (LL_New - LL_Old) + (BC_Mass_Fraction * QLL))
              SOILPROP%DUL(L) = MAX(SOILPROP%LL(L)+0.01, NativeDUL(L) + (DUL_New - DUL_Old) + (BC_Mass_Fraction * KDUL))
              SOILPROP%SAT(L) = MAX(SOILPROP%DUL(L)+0.01, 1.0 - (SOILPROP%BD(L)/2.65))
          END DO
      END SUBROUTINE Biochar_UpdateSoilProps

!=======================================================================
!  GetBiocharPriming
!  Purpose: Provides priming modifiers to the SOM decomposition modules.
!=======================================================================
      SUBROUTINE GetBiocharPriming(L, BC_Tot, P_Rate, P_Eff, P_Biom)
          INTEGER, INTENT(IN)  :: L        ! Soil Layer
          REAL,    INTENT(OUT) :: BC_Tot   ! Total Biochar C (kg/ha)
          REAL,    INTENT(OUT) :: P_Rate   ! Priming on decomp rate
          REAL,    INTENT(OUT) :: P_Eff    ! Priming on efficiency
          REAL,    INTENT(OUT) :: P_Biom   ! Priming on partitioning
          
          IF (BC_Model_Type /= 1) THEN
             BC_Tot = 0.0
             P_Rate = 1.0
             P_Eff = 1.0
             P_Biom = 1.0
             RETURN
          ENDIF

          BC_Tot = BC_Labile(L) + BC_Recalc(L)
          P_Rate = 1.0 + P_FOM * (BC_Tot / 10000.0)
          P_Eff  = MAX(0.0, 1.0 + P_E * (BC_Tot / 10000.0))
          P_Biom = MAX(0.0, 1.0 + P_F * (BC_Tot / 10000.0))
      END SUBROUTINE GetBiocharPriming

!=======================================================================
!  SaxtonRawls: Pedotransfer logic
!=======================================================================
      SUBROUTINE SaxtonRawls(S, C, OM, BD, LL, DUL, SAT)
          REAL, INTENT(IN)  :: S, C, OM
          REAL, INTENT(OUT) :: BD, LL, DUL, SAT
          REAL :: T1500t, T1500, T33t, T33, TS33t, TS33

          T1500t = -0.024*S + 0.487*C + 0.006*OM + 0.005*(S*OM) - 0.013*(C*OM) + 0.068*(S*C) + 0.031
          T1500  = T1500t + (0.14 * T1500t - 0.02)
          LL     = T1500

          T33t   = -0.251*S + 0.195*C + 0.011*OM + 0.006*(S*OM) - 0.027*(C*OM) + 0.452*(S*C) + 0.299
          T33    = T33t + (1.283 * T33t**2 - 0.374 * T33t - 0.015)
          DUL    = T33

          TS33t  = 0.278*S + 0.034*C + 0.022*OM - 0.018*(S*OM) - 0.027*(C*OM) - 0.584*(S*C) + 0.078
          TS33   = TS33t + (0.636 * TS33t - 0.107)
          SAT    = DUL + TS33 - 0.097*S + 0.043
          BD     = (1.0 - SAT) * 2.65
      END SUBROUTINE SaxtonRawls

!=======================================================================
! Dominic biochar model routines
!=======================================================================

  SUBROUTINE Biochar_Derivatives(t, y, dydt, SOILPROP, L)
    USE ModuleDefs
    IMPLICIT NONE
    REAL, INTENT(IN) :: t
    REAL, DIMENSION(8), INTENT(IN) :: y
    REAL, DIMENSION(8), INTENT(OUT) :: dydt
    TYPE (SoilType), INTENT(IN) :: SOILPROP
    INTEGER, INTENT(IN) :: L

    REAL :: BC_L, BC_R, M_BC, CEC_pot, Tot_NH4, Tot_NO3, Tot_PO4, P_precip
    REAL :: pH_dynamic, CEC_eff, fraction_NH3, frac_sorbed_NH4
    REAL :: NH4_aq, NH3_aq, AEC_bridge, comp_denom
    REAL :: PO4_aq, NO3_aq
    REAL :: dC_pot, N_req_max, N_req_min, N_avail, N_index, CUE_dyn
    REAL :: R_decomp, R_immob_N, eta_N, R_ox, R_nitrif, H_load_nitric
    REAL :: H_load_total, R_weather, R_volat, R_precip_P
    REAL :: immob_NH4, immob_NO3
    REAL :: dBC_L, dM_BC, dCEC_pot, dTot_NH4, dTot_NO3, dTot_PO4, dP_precip

    ! Unpack state
    BC_L = MAX(0.0, y(1))
    BC_R = MAX(0.0, y(2))
    M_BC = MAX(0.0, y(3))
    CEC_pot = MAX(0.0, y(4))
    Tot_NH4 = MAX(0.0, y(5))
    Tot_NO3 = MAX(0.0, y(6))
    Tot_PO4 = MAX(0.0, y(7))
    P_precip = MAX(0.0, y(8))

    ! 1. pH and CEC Partitioning
    pH_dynamic = SOILPROP%PH(L) + (M_BC * 0.02) 
    
    ! Henderson-Hasselbalch for Effective CEC
    CEC_eff = CEC_pot * (1.0 / (1.0 + 10.0**(pKa_carboxyl - pH_dynamic)))
    
    ! Henderson-Hasselbalch for Ammonia Volatilization potential
    fraction_NH3 = 1.0 / (1.0 + 10.0**(pKa_NH4 - pH_dynamic))
    
    ! Cation exchange for NH4
    frac_sorbed_NH4 = MIN(0.9, (CEC_eff * 0.1) / (Tot_NH4 + 1.0e-6))
    NH4_aq   = Tot_NH4 - (Tot_NH4 * frac_sorbed_NH4)
    NH3_aq   = NH4_aq * fraction_NH3
    
    ! 2. Cation Bridging & Anion Competition
    AEC_bridge = CEC_eff * f_poly * k_bridge_eff
    comp_denom = 1.0 + (K_L_NO3 * Tot_NO3) + (K_L_PO4 * Tot_PO4)
    
    NO3_aq = Tot_NO3 - MIN(AEC_bridge * ((K_L_NO3 * Tot_NO3) / comp_denom), Tot_NO3)
    PO4_aq = Tot_PO4 - MIN(AEC_bridge * ((K_L_PO4 * Tot_PO4) / comp_denom), Tot_PO4)
    
    ! 3. Kinetic Rates
    
    ! Carbon Degradation
    dC_pot = BC_L * k_labile
    N_req_max = dC_pot * (CUE_max / CN_mic)
    N_req_min = dC_pot * (CUE_min / CN_mic)
    
    N_avail = NH4_aq + NO3_aq
    N_index = MIN(1.0, N_avail / (N_req_max + 1.0e-6))
    CUE_dyn = CUE_min + (CUE_max - CUE_min) * N_index
    
    eta_N = MIN(1.0, N_avail / (N_req_min + 1.0e-6))
    R_decomp = dC_pot * eta_N
    R_immob_N = R_decomp * (CUE_dyn / CN_mic)
    
    ! Surface Oxidation
    R_ox = k_ox_max * ((Dominic_CEC_max * (BC_R/10000.0)) - CEC_pot)
    
    ! Nitrification & Weathering
    R_nitrif = k_nitrif * NH4_aq
    H_load_nitric = R_nitrif * 2.0
    H_load_total  = H_load_nitric + 0.01 ! background
    
    R_weather = k_weather * M_BC * (H_load_total**0.8)
    
    ! Volatilization & Precipitation
    R_volat = k_volat * NH3_aq
    R_precip_P = 0.05 * R_weather * PO4_aq
    
    ! 4. Derivatives
    immob_NH4 = R_immob_N * 0.8
    immob_NO3 = R_immob_N * 0.2
    
    dBC_L = -R_decomp
    dM_BC = -R_weather
    dCEC_pot = R_ox
    
    dTot_NH4 = -R_nitrif - R_volat - immob_NH4
    dTot_NO3 =  R_nitrif - immob_NO3
    dTot_PO4 = -R_precip_P
    dP_precip = R_precip_P
    
    ! Pack derivatives
    dydt(1) = dBC_L
    dydt(2) = 0.0 ! BC_R does not change
    dydt(3) = dM_BC
    dydt(4) = dCEC_pot
    dydt(5) = dTot_NH4
    dydt(6) = dTot_NO3
    dydt(7) = dTot_PO4
    dydt(8) = dP_precip

  END SUBROUTINE Biochar_Derivatives

!=======================================================================
  SUBROUTINE RK45_Integrate(y, t_start, t_end, tol, SOILPROP, L)
    USE ModuleDefs
    IMPLICIT NONE
    REAL, DIMENSION(8), INTENT(INOUT) :: y
    REAL, INTENT(IN) :: t_start, t_end, tol
    TYPE (SoilType), INTENT(IN) :: SOILPROP
    INTEGER, INTENT(IN) :: L

    REAL :: t, dt, scale
    REAL, DIMENSION(8) :: y_new, y_temp, error
    REAL, DIMENSION(8) :: k1, k2, k3, k4, k5, k6
    REAL :: err_max

    ! Fehlberg coefficients
    REAL, PARAMETER :: b21 = 0.25
    REAL, PARAMETER :: b31 = 3.0/32.0, b32 = 9.0/32.0
    REAL, PARAMETER :: b41 = 1932.0/2197.0, b42 = -7200.0/2197.0, b43 = 7296.0/2197.0
    REAL, PARAMETER :: b51 = 439.0/216.0, b52 = -8.0, b53 = 3680.0/513.0, b54 = -845.0/4104.0
    REAL, PARAMETER :: b61 = -8.0/27.0, b62 = 2.0, b63 = -3544.0/2565.0, b64 = 1859.0/4104.0, b65 = -11.0/40.0

    REAL, PARAMETER :: c1 = 25.0/216.0, c3 = 1408.0/2565.0, c4 = 2197.0/4104.0, c5 = -0.15
    REAL, PARAMETER :: c2 = 0.0, c6 = 0.0 ! for 4th order

    REAL, PARAMETER :: chat1 = 16.0/135.0, chat3 = 6656.0/12825.0, chat4 = 28561.0/56430.0, chat5 = -9.0/50.0, chat6 = 2.0/55.0
    REAL, PARAMETER :: chat2 = 0.0 ! for 5th order

    t = t_start
    dt = 1.0 ! Initial guess: 1 hour

    DO WHILE (t < t_end)
       IF (t + dt > t_end) dt = t_end - t

       CALL Biochar_Derivatives(t, y, k1, SOILPROP, L)
       
       y_temp = y + dt * b21 * k1
       CALL Biochar_Derivatives(t + 0.25*dt, y_temp, k2, SOILPROP, L)
       
       y_temp = y + dt * (b31*k1 + b32*k2)
       CALL Biochar_Derivatives(t + 0.375*dt, y_temp, k3, SOILPROP, L)
       
       y_temp = y + dt * (b41*k1 + b42*k2 + b43*k3)
       CALL Biochar_Derivatives(t + (12.0/13.0)*dt, y_temp, k4, SOILPROP, L)
       
       y_temp = y + dt * (b51*k1 + b52*k2 + b53*k3 + b54*k4)
       CALL Biochar_Derivatives(t + dt, y_temp, k5, SOILPROP, L)
       
       y_temp = y + dt * (b61*k1 + b62*k2 + b63*k3 + b64*k4 + b65*k5)
       CALL Biochar_Derivatives(t + 0.5*dt, y_temp, k6, SOILPROP, L)
       
       ! 4th order estimate
       y_new = y + dt * (c1*k1 + c3*k3 + c4*k4 + c5*k5)
       
       ! 5th order estimate
       y_temp = y + dt * (chat1*k1 + chat3*k3 + chat4*k4 + chat5*k5 + chat6*k6)
       
       ! Error estimate
       error = abs(y_temp - y_new)
       err_max = maxval(error)
       
       ! Scale for step size adjustment
       scale = 0.84 * (tol / (err_max + 1.0e-10))**0.25
       scale = min(max(scale, 0.1), 4.0) ! Limit change
       
       IF (err_max <= tol) THEN
          y = y_temp ! Accept 5th order result
          t = t + dt
          dt = dt * scale
       ELSE
          dt = dt * scale ! Reject and reduce dt
       ENDIF
       
    END DO

  END SUBROUTINE RK45_Integrate

!=======================================================================
  SUBROUTINE Biochar_Daily_Dominic(CONTROL, SOILPROP, NH4, NO3, SPi_AVAIL)
    USE ModuleDefs
    IMPLICIT NONE

    TYPE (ControlType), INTENT(IN) :: CONTROL
    TYPE (SoilType), INTENT(INOUT) :: SOILPROP
    REAL, DIMENSION(NL), INTENT(INOUT) :: NH4, NO3, SPi_AVAIL

    INTEGER :: L, YEAR, DOY, iApp
    REAL, DIMENSION(8) :: y
    REAL :: tol
    REAL :: Amt_L, Amt_R, Scale_Factor

    IF (BC_Model_Type /= 2) RETURN

    IF (.NOT. Initialized) CALL Biochar_Init(CONTROL)

    tol = 1.0e-5
    CALL YR_DOY(CONTROL%YRDOY, YEAR, DOY)

    SELECT CASE (CONTROL%DYNAMIC)
    CASE (INTEGR)
        ! Apply Biochar if application date is reached
        DO iApp = 1, NumApps
           IF (CONTROL%YRDOY >= BC_Apps(iApp)%AppDate .AND. .NOT. Applied(iApp)) THEN
              Amt_L = BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                      BC_Apps(iApp)%FCarbon * BC_Apps(iApp)%FLabile
              Amt_R = BC_Apps(iApp)%Amount * (1.0-BC_Apps(iApp)%FLoss) * &
                      BC_Apps(iApp)%FCarbon * (1.0-BC_Apps(iApp)%FLabile)
              
              Scale_Factor = BC_Apps(iApp)%Amount / 10000.0 ! Scale based on original assumption of 10000 kg/ha
              
              CALL DistributeBiochar_Dominic(Amt_L, Amt_R, 50.0 * Scale_Factor, 0.5 * Scale_Factor, BC_Apps(iApp)%Depth, SOILPROP)
              Applied(iApp) = .TRUE.
           ENDIF
        ENDDO

        DO L = 1, SOILPROP%NLAYR
           
           ! Pack state
           y(1) = BCState%BC_L(L)
           y(2) = BCState%BC_R(L)
           y(3) = BCState%M_BC(L)
           y(4) = BCState%CEC_pot(L)
           y(5) = NH4(L)
           y(6) = NO3(L)
           y(7) = SPi_AVAIL(L)
           y(8) = BCState%P_precip(L)

           ! Integrate from 0 to 24 hours
           IF (CONTROL%YRDOY == 2012130 .AND. L == 1) WRITE(*,*) "DEBUG INTEGRATE BEFORE: y(1)=", y(1)
           CALL RK45_Integrate(y, 0.0, 24.0, tol, SOILPROP, L)
           IF (CONTROL%YRDOY == 2012130 .AND. L == 1) WRITE(*,*) "DEBUG INTEGRATE AFTER: y(1)=", y(1)
           
           ! Unpack state
           BCState%BC_L(L) = y(1)
           BCState%BC_R(L) = y(2)
           BCState%M_BC(L) = y(3)
           BCState%CEC_pot(L) = y(4)
           NH4(L) = MAX(0.0, y(5))
           NO3(L) = MAX(0.0, y(6))
           SPi_AVAIL(L) = MAX(0.0, y(7))
           BCState%P_precip(L) = MAX(0.0, y(8))
           
           ! Update soil properties (pH and CEC)
           SOILPROP%PH(L) = SOILPROP%PH(L) + (BCState%M_BC(L) * 0.02) ! simplified
           SOILPROP%CEC(L) = SOILPROP%CEC(L) + BCState%CEC_pot(L) * (1.0 / (1.0 + 10.0**(pKa_carboxyl - SOILPROP%PH(L)))) ! simplified
           
        END DO

    CASE (OUTPUT)
        IF (FirstOutput) THEN
           OPEN(NEWUNIT=LUN_BC, FILE='BIOCHAR_DOMINIC.OUT', STATUS='REPLACE')
           WRITE(LUN_BC,'(A)') "! Dominic Biochar Model Output"
           WRITE(LUN_BC,'(A)') "@YEAR DOY DAS   L   BC_L   BC_R   M_BC   CEC_pot   NH4   NO3   SPi_AVAIL   P_precip   SLPH   CEC"
           FirstOutput = .FALSE.
        ENDIF
        DO L = 1, SOILPROP%NLAYR
           WRITE(LUN_BC, '(I5, I4, I5, I4, 10F12.4)') YEAR, DOY, CONTROL%DAS, L, &
                 BCState%BC_L(L), BCState%BC_R(L), BCState%M_BC(L), BCState%CEC_pot(L), &
                 NH4(L), NO3(L), SPi_AVAIL(L), BCState%P_precip(L), SOILPROP%PH(L), SOILPROP%CEC(L)
        END DO
        FLUSH(LUN_BC)
    END SELECT
  END SUBROUTINE Biochar_Daily_Dominic

END MODULE Biochar_mod

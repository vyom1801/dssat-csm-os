MODULE Biochar_mod
!=======================================================================
!  MODULE Biochar_mod
!  Purpose: Integrated Biochar model for DSSAT. 
!  Includes: Application, Decay (2 pools), N-release/Immobilization,
!            CEC Aging, pH Liming, and NH4 Adsorption.
!=======================================================================
      USE ModuleDefs
      USE ModuleData
      IMPLICIT NONE
      SAVE

      TYPE BiocharAppType
        INTEGER :: AppDate
        REAL    :: Amount, Depth, FLoss, FCarbon, FLabile
        REAL    :: MRT_Labile, MRT_Recalc, CN_BC
        REAL    :: CEC_INIT, BCLV, Kads, Kdes
        REAL    :: QLL, KDUL, KBD
      END TYPE BiocharAppType

      INTEGER, PARAMETER :: MaxApp = 20
      TYPE(BiocharAppType) :: BC_Apps(MaxApp)
      INTEGER :: NumApps = 0
      LOGICAL :: Applied(MaxApp) = .FALSE.

      ! Global Parameters
      REAL :: CNRF_BC = 0.693, Opt_bc = 25.0, EF_BC = 0.4, FR_BCBIOM = 0.05
      REAL :: CN_BIOM = 8.0, CN_HUM = 11.0, CEC_MAX = 100.0, K_CEC = 0.001
      REAL :: UpH = 8.3, LpH = 3.5, P1_pH = 10.0
      REAL :: P_FOM = 0.0, P_E = 0.0, P_F = 0.0

      ! State Variables
      REAL, DIMENSION(NL) :: BC_Labile = 0.0, BC_Recalc = 0.0, BC_NH4_Ads = 0.0
      REAL, DIMENSION(NL) :: NativeCEC = 0.0, Prev_BC_Mass_g_g = 0.0
      REAL, DIMENSION(NL) :: dlt_nbc_rel_prev = 0.0
      
      ! Daily Fluxes
      REAL :: Daily_CO2_Gross, Daily_Biom_Gross, Daily_Hum_Gross, Daily_N_Net

      INTEGER :: LUN_BC = 0
      LOGICAL :: FirstOutput = .TRUE., FirstRun = .TRUE.

      CONTAINS

!=======================================================================
      SUBROUTINE Biochar_Init(CONTROL)
        TYPE(ControlType), INTENT(IN) :: CONTROL
        INTEGER :: ERRNUM, LUN_INP
        CHARACTER(LEN=120) :: LINE
        LOGICAL :: FEXIST
        NumApps = 0
        Applied = .FALSE.
        BC_Labile = 0.0; BC_Recalc = 0.0; BC_NH4_Ads = 0.0

        INQUIRE(FILE='BIOCHAR.INP', EXIST=FEXIST)
        IF (.NOT. FEXIST) THEN
           WRITE(*,*) "BIOCHAR: BIOCHAR.INP NOT FOUND. SKIPPING."
           RETURN
        ENDIF

        OPEN(NEWUNIT=LUN_INP, FILE='BIOCHAR.INP', STATUS='OLD', ACTION='READ')
        DO WHILE (.TRUE.)
           READ(LUN_INP, '(A)', IOSTAT=ERRNUM) LINE
           IF (ERRNUM /= 0) EXIT
           LINE = ADJUSTL(LINE)
           IF (LINE(1:1) == '!' .OR. LINE == '') CYCLE
           
           IF (LINE(1:6) == '@PARAM') THEN
              READ(LUN_INP, *, IOSTAT=ERRNUM) CNRF_BC, Opt_bc, P_FOM, P_E, P_F, CEC_MAX, K_CEC
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
                BC_Apps(NumApps)%CEC_INIT, BC_Apps(NumApps)%BCLV, &
                BC_Apps(NumApps)%Kads, BC_Apps(NumApps)%Kdes, &
                BC_Apps(NumApps)%QLL, BC_Apps(NumApps)%KDUL, BC_Apps(NumApps)%KBD
        END DO
        CLOSE(LUN_INP)
        WRITE(*,*) "BIOCHAR: Loaded ", NumApps, " applications."
      END SUBROUTINE Biochar_Init

!=======================================================================
      SUBROUTINE Biochar_Daily(CONTROL, SOILPROP, SW, ST, NH4, NO3, IMM, MNR)
        TYPE(ControlType), INTENT(IN) :: CONTROL
        TYPE(SoilType),    INTENT(INOUT) :: SOILPROP
        REAL, DIMENSION(NL), INTENT(IN)  :: SW, ST, NH4, NO3
        REAL, DIMENSION(0:NL, NELEM), INTENT(INOUT) :: IMM, MNR
        
        INTEGER :: YRDOY, L, iApp, YEAR, DOY
        REAL :: WF, TF, NF, MF, DecayRate1, DecayRate2, dltBC1, dltBC2, dlt_Total
        REAL :: dlt_nbc_need, dlt_nbc_released, dlt_nbc
        REAL :: SoilMass, BC_Mass_g_g, Age, CEC_t, MassInLayer

        YRDOY = CONTROL%YRDOY
        CALL YR_DOY(YRDOY, YEAR, DOY)
        IF (FirstRun) THEN
           NativeCEC = SOILPROP%CEC
           FirstRun = .FALSE.
        ENDIF

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

           ! 2. DECAY & N-FLUX
           Daily_CO2_Gross = 0.0; Daily_N_Net = 0.0
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
              
              ! N Mineralization/Immobilization
              dlt_nbc_need = (dlt_Total * EF_BC * FR_BCBIOM / CN_BIOM) + &
                             (dlt_Total * EF_BC * (1.0-FR_BCBIOM) / CN_HUM)
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
              OPEN(NEWUNIT=LUN_BC, FILE='BIOCHAR.OUT', STATUS='REPLACE')
              WRITE(LUN_BC,'(A)') "@YEAR DOY DAS   BC_Labile   BC_Recalc   dlt_CO2   dlt_N_Net"
              FirstOutput = .FALSE.
           ENDIF
           WRITE(LUN_BC, '(I5, I4, I5, 4F12.4)') YEAR, DOY, CONTROL%DAS, &
                 SUM(BC_Labile), SUM(BC_Recalc), Daily_CO2_Gross, Daily_N_Net
        END SELECT
      END SUBROUTINE Biochar_Daily

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

      SUBROUTINE DistributeBiochar(Labile, Recalc, Depth, SOILPROP)
        REAL, INTENT(IN) :: Labile, Recalc, Depth
        TYPE(SoilType), INTENT(IN) :: SOILPROP
        INTEGER :: L
        REAL :: LDepth = 0.0, Thick, Dist, Frac
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
              OM_New = OM_Nat + (BC_Mass_Fraction * EXP(BC_Apps(1)%KBD)) ! Effective OM

              ! 3. Get Native and New Properties via Saxton-Rawls
              CALL SaxtonRawls(S, C, OM_Nat, BD_Old, LL_Old, DUL_Old, SAT_Old)
              CALL SaxtonRawls(S, C, OM_New, BD_New, LL_New, DUL_New, SAT_New)

              ! 4. Apply Delta to DSSAT Soil Object
              SOILPROP%BD(L)  = MAX(0.5, MIN(2.0, SOILPROP%BD(L) + (BD_New - BD_Old)))
              SOILPROP%LL(L)  = MAX(0.01, SOILPROP%LL(L) + (LL_New - LL_Old))
              SOILPROP%DUL(L) = MAX(SOILPROP%LL(L)+0.01, SOILPROP%DUL(L) + (DUL_New - DUL_Old))
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

      END MODULE Biochar_mod
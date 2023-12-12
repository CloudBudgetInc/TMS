/**
 * Created by Alex JR on 9/2/2020.
 */
@isTest
public with sharing class CBTestTMS {

    private static List<cb4__CBDimension__c> d = new List<cb4__CBDimension__c>();
    static Object o, o1;
    public static String CRON_EXP = '0 0 * * * ? *';
    static Boolean ec = false;
    static Map<String, Id> dMap = cb4.CBUtils.dimensionNameIdMap;
    static List<cb4.CBSO> SO;
    static Id BY_ID { // BY Tag Id
        get {
            if (BY_ID == null) {
                List<cb4__CBTag__c> t = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = :cb4.CBConstant.BUDGET_YEAR_DIM];
                if (t.size() > 0) BY_ID = t[0].Id;
            }
            return BY_ID;
        }
        set;
    }

    @testSetup static void setup() {
        add('Account');
        add('Account Subtype');
        add('Account Type');
        add('BDG');
        add('Budget App Template');
        add('Budget App');
        add('Budget App Amount');
        add('Budget Year');
        add('Department');
        add('Entry');
        add('Entry Amount');
        add('Entry Type');
        add('Entry Class');
        add('Scenario');
        add('Period');
        add('City');
        add('Budget Reporting Department');
        add('CB_FF Mapping Configuration');
        add('Calculation Rule');
        insert d; // 1
        cb4.CBUtils.dimensionNameIdMap = null;
        Map<String, String> dMap = cb4.CBUtils.dimensionNameIdMap;

        System.debug('dMap = ' + dMap);
        System.debug([SELECT Name FROM cb4__CBDimension__c]);

        List<cb4__CBTag__c> t1 = new List<cb4__CBTag__c>(); // first order insert
        cb4__CBTag__c IVAN = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('BDG'), Name = 'Ivan');
        cb4__CBTag__c BYT = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget Year'), Name = '2020');
        cb4__CBTag__c BYT2 = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget Year'), Name = '2021');
        cb4__CBTag__c DEP = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Department'), Name = 'NY');
        cb4__CBTag__c ACCTYPE = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Account Type'), Name = 'Expense');
        cb4__CBTag__c ETYPE = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry Type'), Name = 'Expense');
        cb4__CBTag__c ECLASS = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry Class'), Name = 'Planned');
        cb4__CBTag__c ECLASSACT = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry Class'), Name = 'Actual');
        cb4__CBTag__c BASESCENARIO = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Scenario'), Name = 'Base');
        cb4__CBTag__c FCSTSCENARIO = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Scenario'), Name = 'Forecast');
        cb4__CBTag__c CITY = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('City'), Name = 'Calgary');
        cb4__CBTag__c FFCONF = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('CB_FF Mapping Configuration'), Name = 'Default Configuration');
        t1.add(IVAN);
        t1.add(BYT);
        t1.add(BYT2);
        t1.add(DEP);
        t1.add(ACCTYPE);
        t1.add(ETYPE);
        t1.add(ECLASS);
        t1.add(ECLASSACT);
        t1.add(BASESCENARIO);
        t1.add(FCSTSCENARIO);
        t1.add(CITY);
        t1.add(FFCONF);
        insert t1; //3

        List<cb4__CBTag__c> t2 = new List<cb4__CBTag__c>(); // second order insert
        cb4__CBTag__c ENTRY = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry'), Name = 'Entry', cb4__Tag8__c = BASESCENARIO.Id, cb4__Tag1__c = BYT.Id, cb4__Tag2__c = DEP.Id, cb4__Tag3__c = ETYPE.Id, cb4__Tag4__c = ECLASS.Id);
        cb4__CBTag__c ENTRYACTUAL = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry'), Name = 'Entry', cb4__Tag8__c = BASESCENARIO.Id, cb4__Tag1__c = BYT.Id, cb4__Tag2__c = DEP.Id, cb4__Tag3__c = ETYPE.Id, cb4__Tag4__c = ECLASSACT.Id);
        cb4__CBTag__c PERIOD = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Period'), Name = 'JAN20', cb4__Start__c = Date.newInstance(2020, 1, 1), cb4__End__c = Date.newInstance(2020, 1, 30), cb4__Tag1__c = BYT.Id, cb4__OrderNumber__c = 1);
        cb4__CBTag__c PERIOD2 = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Period'), Name = 'FEB20', cb4__Start__c = Date.newInstance(2020, 2, 1), cb4__End__c = Date.newInstance(2020, 2, 28), cb4__Tag1__c = BYT.Id, cb4__OrderNumber__c = 2);
        cb4__CBTag__c PERIOD3 = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Period'), Name = 'JAN21', cb4__Start__c = Date.newInstance(2021, 1, 1), cb4__End__c = Date.newInstance(2021, 1, 30), cb4__Tag1__c = BYT2.Id, cb4__OrderNumber__c = 1);
        cb4__CBTag__c PERIOD4 = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Period'), Name = 'FEB21', cb4__Start__c = Date.newInstance(2021, 2, 1), cb4__End__c = Date.newInstance(2021, 2, 28), cb4__Tag1__c = BYT2.Id, cb4__OrderNumber__c = 2);
        cb4__CBTag__c ACCST = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Account Subtype'), Name = 'Travel', cb4__Tag1__c = ACCTYPE.Id);
        t2.add(ENTRY);
        t2.add(ENTRYACTUAL);
        t2.add(PERIOD);
        t2.add(PERIOD2);
        t2.add(PERIOD3);
        t2.add(PERIOD4);
        t2.add(ACCST);
        insert t2; // 4

        List<cb4__CBTag__c> t3 = new List<cb4__CBTag__c>(); // third order insert
        cb4__CBTag__c ACC = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Account'), Name = 'Air', cb4__Tag1__c = ACCST.Id);
        t3.add(ACC);
        insert t3; //5

        cb4__CBTag__c cRul1 = new cb4__CBTag__c(Name = 'New Result Calculation Rule',  cb4__Boolean1__c = true, cb4__Boolean2__c = true, cb4__Boolean3__c = false, cb4__Boolean4__c = false, cb4__Boolean5__c = false, cb4__Boolean6__c = false,
                cb4__Decimal1__c = 0.00, cb4__Decimal2__c = 0.00, cb4__Decimal3__c = 0.00, cb4__Dimension__c= dMap.get('Calculation Rule'), cb4__Status__c = 'Open', cb4__Tag1__c = ACC.Id, cb4__Text1__c = 'Result');
        insert cRul1;
        cb4__CBTag__c cRul2 = new cb4__CBTag__c(Name = 'Compensated Leave = 1.5%* Salaries', cb4__Boolean1__c = false, cb4__Boolean2__c = false, cb4__Boolean3__c = false, cb4__Boolean4__c = false, cb4__Boolean5__c = false, cb4__Boolean6__c = false,
                cb4__Decimal1__c = 1.50, cb4__Decimal2__c = 0.00, cb4__Decimal3__c = 0.00, cb4__Dimension__c = dMap.get('Calculation Rule'), cb4__Status__c = 'Open', cb4__Tag1__c = ACC.Id, cb4__Tag2__c= cRul1.Id, cb4__Tag3__c = BYT.Id, cb4__Text1__c = 'Simple', cb4__Text2__c = 'Percent');
        insert cRul2;

        cb4__CBTag__c BATEMPL = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget App Template'), Name = 'Tmpl', cb4__Tag4__c = cRul2.Id);
        insert BATEMPL;

        cb4__CBTag__c BUDGET = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget App'), Name = 'BDG', cb4__Tag2__c = BATEMPL.Id, cb4__Tag3__c = BYT.Id, cb4__Tag8__c = BASESCENARIO.Id, cb4__Tag4__c = DEP.Id);
        insert BUDGET;
        cb4__CBTag__c BUDGETFCST = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget App'), Name = 'BDG', cb4__Tag2__c = BATEMPL.Id, cb4__Tag3__c = BYT.Id, cb4__Tag8__c = FCSTSCENARIO.Id, cb4__Tag4__c = DEP.Id);
        insert BUDGETFCST;


        List<cb4__CBTag__c> t4 = new List<cb4__CBTag__c>(); // 4-th order insert
        cb4__CBTag__c ENTRYAM = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry Amount'), cb4__Text1__c = 'main', cb4__Tag1__c = ENTRY.Id, cb4__Tag2__c = ACC.Id, cb4__Tag3__c = PERIOD.Id, cb4__Decimal1__c = 1, cb4__Text2__c = 'Dr');
        cb4__CBTag__c ENTRYAMFCST = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Entry Amount'), cb4__Text1__c = 'main', cb4__Tag1__c = ENTRYACTUAL.Id, cb4__Tag2__c = ACC.Id, cb4__Tag3__c = PERIOD.Id, cb4__Decimal1__c = 1, cb4__Text2__c = 'Dr');
        cb4__CBTag__c BUDGETAMOUNT = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget App Amount'), cb4__Text1__c = 'expense', cb4__Text2__c = 'expense', cb4__Text3__c = 'tt', cb4__Tag1__c = BUDGET.Id, cb4__Tag2__c = ACC.Id, cb4__Tag3__c = PERIOD.Id, cb4__Decimal1__c = 1);
        cb4__CBTag__c BUDGETAMOUNTFCST = new cb4__CBTag__c(cb4__Dimension__c = dMap.get('Budget App Amount'), cb4__Text1__c = 'expense', cb4__Text2__c = 'expense', cb4__Text3__c = 'tt', cb4__Tag1__c = BUDGETFCST.Id, cb4__Tag2__c = ACC.Id, cb4__Tag3__c = PERIOD.Id, cb4__Decimal1__c = 1);
        t4.add(ENTRYAM);
        t4.add(ENTRYAMFCST);
        t4.add(BUDGETAMOUNT);
        t4.add(BUDGETAMOUNTFCST);
        insert t4; // 6

        List<sObject> obj = new List<sObject>();
        cb4__CBalanceRule__c br = new cb4__CBalanceRule__c(cb4__AmountField__c = 'cb4__Decimal1__c', cb4__ColumnField__c = 'cb4__Tag3__c', cb4__DimensionType__c = dMap.get('Entry Amount'));
        obj.add(br);
        cb4__CBUserContext__c uc = cb4__CBUserContext__c.getInstance(UserInfo.getUserId());
        uc = new cb4__CBUserContext__c(cb4__Dimension1__c = dMap.get('Budget Year'), cb4__Tag1__c = BYT.Id, cb4__Tag2__c = BYT.Id, cb4__Tag3__c = BYT.Id, cb4__Tag4__c = BYT.Id, cb4__Tag5__c = BYT.Id);
        obj.add(uc);
        cb4__CBLog__c l = new cb4__CBLog__c(cb4__Type__c = 'DEBUG', cb4__Title__c = 't', cb4__Description__c = 'd');
        obj.add(l);
        cb4__CBLoadRule__c lrACC = new cb4__CBLoadRule__c(Name = 'Account', cb4__Column1__c = '{"Tag1__c":"SubType","required":"false","unique":"true"}') ;
        obj.add(lrACC);
        cb4__CBLoadRule__c lrEMP = new cb4__CBLoadRule__c(Name = 'Member', cb4__Column1__c = '{"Tag1__c":"SubType","required":"false","unique":"true"}') ;
        obj.add(lrEMP);
        insert obj; // 2


        Budget_Reporting_Department__c brd = new Budget_Reporting_Department__c(Name = 'Test1', Reporting_Level__c = 'Level 1');
        insert brd;
        Budget_Reporting_Department__c brd2 = new Budget_Reporting_Department__c(Name = 'Test2', Reporting_Level__c = 'Level 2');
        insert brd2;
        Budget_Reporting_Department__c brd3 = new Budget_Reporting_Department__c(Name = 'Test3', Reporting_Level__c = 'Level 3');
        insert brd3;
        Budget_Reporting_Department_Line__c brdl = new Budget_Reporting_Department_Line__c(Budget_Reporting_Department__c = brd.Id);
        insert brdl;
        Budget_Reporting_Department_Line__c brd2l = new Budget_Reporting_Department_Line__c(Budget_Reporting_Department__c = brd2.Id);
        insert brd2l;
        Budget_Reporting_Department_Line__c brd3l = new Budget_Reporting_Department_Line__c(Budget_Reporting_Department__c = brd3.Id);
        insert brd3l;

        CBGlobalVariable__c CBVariable = new CBGlobalVariable__c();
        CBVariable.EmailRecipients__c = 'akolyadich@cloudbudget.com';
        CBVariable.FY__c = '2020';
        CBVariable.LastUpdateDate__c = System.today();
        insert CBVariable;


        List<cb4__CBalanceRule__c> cbalRules = new List<cb4__CBalanceRule__c>();
        cbalRules.add(new cb4__CBalanceRule__c(cb4__Label__c = 'LVL1 2020'));
        cbalRules.add(new cb4__CBalanceRule__c(cb4__Label__c = 'LVL2 2020'));
        cbalRules.add(new cb4__CBalanceRule__c(cb4__Label__c = 'LVL3 2020'));
        cbalRules.add(new cb4__CBalanceRule__c(cb4__Label__c = 'CBRB 2020 Base', cb4__AmountField__c = 'cb4__Decimal1__c', cb4__ColumnField__c = 'cb4__Tag3__c', cb4__DimensionType__c = dMap.get('Entry Amount')));
        cbalRules.add(new cb4__CBalanceRule__c(cb4__Label__c = 'CBRB 2020 Forecast', cb4__AmountField__c = 'cb4__Decimal1__c', cb4__ColumnField__c = 'cb4__Tag3__c', cb4__DimensionType__c = dMap.get('Entry Amount')));
        insert cbalRules;

        c2g__codaIntersectDefinition__c newIntersect = new c2g__codaIntersectDefinition__c(c2g__FullAccountingCode__c = true);
        insert newIntersect;

        CBBDGMapping__c cbdbMapping = new CBBDGMapping__c(ReportingDepartment1__c = brd.Id, ReportingDepartment2__c = brd2.Id, ReportingDepartment3__c = brd3.Id, BDG__c = IVAN.Id);
        insert cbdbMapping;

        c2g__codaDimension1__c ffDim1 = new c2g__codaDimension1__c(ESi_Location_Grouping__c = 'Edmonton', Name = 'Edmonton', c2g__ReportingCode__c = '7', ESi_Location_Type__c = 'Office');
        insert ffDim1;
        
        /*c2g__codaGeneralLedgerAccount__c ffAcc = new c2g__codaGeneralLedgerAccount__c(Name = 't', c2g__Type__c = 'Profit And Loss', c2g__ReportingCode__c = '115');
        insert ffAcc;
        c2g__codaIntersectDefinition__c intersect = new c2g__codaIntersectDefinition__c(Name = 'HH', c2g__FullAccountingCode__c = true);
        insert intersect;
        c2g__codaCompany__c company = new c2g__codaCompany__c(Name = 'MST');
        insert company;
        c2g__codaYear__c ffBY = new c2g__codaYear__c(
                Name = '2020',
                c2g__StartDate__c = Date.newInstance(2020, 1, 1),
                c2g__EndDate__c = Date.newInstance(2021, 1, 1),
                c2g__YearEndDate__c = Date.newInstance(2021, 1, 1),
                c2g__YearEndMode__c = 'Full Accounting Code',
                c2g__PeriodCalculationBasis__c = 'Month',
                c2g__Status__c = 'Open',
                c2g__AutomaticPeriodList__c = true);
        insert ffBY;
        c2g__codaPeriod__c ffPeriod = new c2g__codaPeriod__c(Name = '01/20', c2g__YearName__c = ffBY.Id, c2g__OwnerCompany__c = company.Id);
        insert ffPeriod;

        c2g__ReportingBalance__c rb = new c2g__ReportingBalance__c(
                c2g__Type__c = 'Budget',
                c2g__GeneralLedgerAccount__c = ffAcc.Id,
                c2g__Period__c = ffPeriod.Id,
                c2g__OwnerCompany__c = company.Id
        );
        insert rb;*/

    }

    @isTest static void CBTMSController() {
        CBTMSController.runMasterUpdateServer('2020');
        CBTMSController.runCopyAppBudgetServer(null, 'Base', '2020', 'Base', '2021');
        CBTMSController.runCalculationRulesServer('2020');
        CBTMSController.runCitiesSyncServer(null);
        CBTMSController.runBudgetDepartmentsSyncServer(null);
        CBTMSController.runReportingBalanceUpdateServer(null);
        CBTMSController.runForecastUpdateServer(null, 'q1');
        CBTMSController.runForecastUpdateServer(null, 'q2');
        CBTMSController.runForecastUpdateServer(null, 'q3');
        CBTMSController.runForecastUpdateServer(null, 'q4');
        CBTMSController.runUpdateBaseWithActualsServer('2021', 'JAN20');
        CBTMSController.runCBalanceGeneratorServer('2021');
        CBTMSController.runEntriesBDGUpdateServer('2021');
        o = CBTMSController.getParametersSOServer();
        //CBTMSController.saveFYServer('2022');
        o = CBTMSController.getPeriodsSOServer('2021');
        o = CBTMSController.getLockedPeriodServer('2021');
        CBTMSController.lockForecastBudgetsTillServer('2021', 'Apr 2020');
        o = CBTMSController.checkForecastUpdatePeriods('2021', 'Apr2020');
        o = CBTMSController.getProcessStepServer();
        o = CBTMSController.getFFvsCBStatsServer();
        String r = CBTMSController.saveGlobalVariableServer('2021','test@gmail.com');
        CBTMSController.sendTestEmailServer();
        o = CBTMSController.getRBStatisticServer();
        o = CBTMSController.setMap;
        CBTMSController.cg();
        r = CBTMSController.getFcstLockSettings();
        System.assert(true);
    }

    @isTest static void otherClasses() {
        o = CBBDGMapping.BDGMap;

        o = CBMappingReport.getReportDataServer('2020', 'DOUBLED');
        o = CBMappingReport.getReportDataServer('2020', 'UNMAPPED');
        o = CBMappingReport.searchReportingDepartmentsServer(null, null);
        o = CBMappingReport.getUnmappedWrapper(new c2g__ReportingBalance__c(), 'Level 1');
        CBMappingReport.ReportWrapper wr = new CBMappingReport.ReportWrapper();
        wr.budgetReportingDepartmentId = null;
        wr.budgetReportingDepartmentName = null;
        wr.budgetReportingDepartmentLevel = null;
        wr.budgetReportingDepartmentId2 = null;
        wr.budgetReportingDepartmentName2 = null;
        wr.budgetReportingDepartmentLevel2 = null;
        wr.dimension1Name = null;
        wr.dimension2Name = null;
        wr.budgetReportingDepartmentLineId = null;
        wr.budgetReportingDepartmentLineName = null;
        wr.budgetReportingDepartmentLineId2 = null;
        wr.budgetReportingDepartmentLineName2 = null;
        wr.rbExampleId = null;
        wr.rbExampleName = null;
        o = wr.toString();
        o = CBServiceV2.getYearsSO();
        o = CBServiceV2.getBaseYearsSO();
        o = CBServiceV2.getPeriodsSO();


        List<cb4__CBalanceRule__c> rules = [SELECT Id FROM cb4__CBalanceRule__c];
        cb4__CBTag__c entry = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Entry'][0];
        cb4__CBTag__c account = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Account'][0];
        cb4__CBTag__c period = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period'][0];
        cb4__CBReport__c report = new cb4__CBReport__c(cb4__CBalanceRule1__c = rules[0].Id, Name = 'Report');
        insert report;
        String key = 'XXXXXXXXXXXXXXXXXX' + 'XXXXXXXXXXXXXXXXXX' + 'XXXXXXXXXXXXXXXXXX' + account.Id + 'XXXXXXXXXXXXXXXXXX';
        List<cb4__CBalance__c> balances = new List<cb4__CBalance__c>();
        for(cb4__CBalanceRule__c rule : rules){
            balances.add( new cb4__CBalance__c(cb4__Key__c = key, cb4__Column__c = period.Id, cb4__DrillDown__c = entry.Id, cb4__CBalanceRule__c = rule.Id, cb4__Amount1__c = 1, cb4__Amount2__c = 2, cb4__Amount3__c = 3));
        }
        insert balances;
        o = CBRDDrillDown.getDrillDown(key, report.Id, period.Id);


        CBReportingBalancesProcessing.CG();
        o = CBReportingBalancesProcessing.getReportingDepartmentMap();
        o = CBReportingBalancesProcessing.getRBFieldName(1);
        o = CBReportingBalancesProcessing.getRBFieldName(2);
        o = CBReportingBalancesProcessing.getRBFieldName(3);
        o = CBReportingBalancesProcessing.getRBFieldName(4);
        o = CBReportingBalancesProcessing.getRBKey('lvl1', new c2g__ReportingBalance__c());

        CBReportingBalancesProcessingV2.CG();
        o = CBReportingBalancesProcessingV2.getReportingDepartmentMap();
        o = CBReportingBalancesProcessingV2.getRBFieldName(1);
        o = CBReportingBalancesProcessingV2.getRBFieldName(2);
        o = CBReportingBalancesProcessingV2.getRBFieldName(3);
        o = CBReportingBalancesProcessingV2.getRBFieldName(4);
        o = CBReportingBalancesProcessingV2.getRBKey('lvl1', new c2g__ReportingBalance__c(), false);

        CBVariable.saveCurrentFY('2020');
        CBVariable.saveEmailRecipients('akolyadich@cloudbudget.com');

        CB_JOB_START  st = new CB_JOB_START();
        CB_JOB_STEP_1 s1 = new CB_JOB_STEP_1();
        CB_JOB_STEP_2 s2 = new CB_JOB_STEP_2();
        CB_JOB_STEP_3 s3 = new CB_JOB_STEP_3();
        CB_JOB_STEP_4 s4 = new CB_JOB_STEP_4();
        CB_JOB_STEP_5 s5 = new CB_JOB_STEP_5();
        CB_JOB_STEP_6 s6 = new CB_JOB_STEP_6();
        CB_JOB_STEP_7 s7 = new CB_JOB_STEP_7();

        CBReportingBalanceDrillDown.codeGen();
        CBBudgetAppTotalsBatch.cg();

        o = CBReportingDepartmentLinePageController.getBaseAnalyticsServer();
        List<Budget_Reporting_Department_Line__c> brdls = CBReportingDepartmentLinePageController.getAllBRDLServer();
        CBReportingDepartmentLinePageController.cg();


        System.assert(true);

    }

    @isTest
    static void testCBReports() {
        cb4__CBalanceRule__c neCBalanceRule = new cb4__CBalanceRule__c(
                cb4__Lvl1Label__c = '1',
                cb4__Lvl2Label__c = '2',
                cb4__Lvl3Label__c = '3',
                cb4__Lvl4Label__c = '4',
                cb4__Lvl5Label__c = '5',
                cb4__Lvl6Label__c = '6',
                cb4__Lvl7Label__c = '7'
        );
        insert neCBalanceRule;
        cb4__CBReport__c newRep = new cb4__CBReport__c(
                Name = 'my 1st report',
                cb4__CBalanceRule1__c = neCBalanceRule.Id,
                cb4__DisplayedColumns__c = '["plan","simple","actual","Q3"]',
                cb4__FitToPageEnabled__c = true,
                cb4__FixedColumns__c = 3,
                cb4__FractionDigits__c = 0,
                cb4__MaxRowNumber__c = 2000
        );
        insert newRep;
        cb4__CBReportColumn__c col = new cb4__CBReportColumn__c(
                cb4__CBRule1__c = neCBalanceRule.Id,
                cb4__Report__c = newRep.Id
        );
        insert col;
        cb4__CBLog__c log = new cb4__CBLog__c(cb4__Type__c = 'TRACKING');
        insert log;
        cb4__CBReport__c report = CBReportNG.getReportServer(newRep.Id);
        List<cb4__CBReportColumn__c> rc = CBReportNG.getReportColumnsServer(newRep.Id);
        List<String> rh = CBReportNG.getReportHeadersServer(newRep.Id);
        List<cb4__CBalance__c> rcb = CBReportNG.getCBalancesServer(newRep.Id);
        List<String> rdg = CBReportNG.getDisplayGroupsServer(newRep.Id);
        List<String> rm = CBReportNG.getLastUpdateMessageServer(newRep.Id);
    }

    @isTest
    static void testMasterUpdateScheduled() {
        Test.startTest();
        String jobId = System.schedule('testBasicScheduledApex1',
                CRON_EXP,
                new CBMasterUpdateScheduled());
        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE id = :jobId
        ];
        System.assertEquals(CRON_EXP,
                ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        String jobId2 = System.schedule('testBasicScheduledApex2',
                CRON_EXP,
                new CBAddMasterUpdateYear());
        CronTrigger ct2 = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE id = :jobId2
        ];
        System.assertEquals(CRON_EXP,
                ct2.CronExpression);
        System.assertEquals(0, ct2.TimesTriggered);
        String jobId3 = System.schedule('testBasicScheduledApex3',
                CRON_EXP,
                new CBSubMasterUpdateYear());
        CronTrigger ct3 = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE id = :jobId3
        ];
        System.assertEquals(CRON_EXP,
                ct3.CronExpression);
        System.assertEquals(0, ct3.TimesTriggered);
        Test.stopTest();
    }

    @isTest static void CBApprovalProcessTMS() {
		List <user> userList = [Select Id,Name,CBBudgetManager__c from user where isActive=true and CBBudgetManager__c != null];
        Set<Id> allManagers = new Set<Id>();
        Set<Id> allUsersWithManagers = new Set<Id>();
        for (user currUser : userList) {
          allManagers.add(currUser.CBBudgetManager__c);
          allUsersWithManagers.add(currUser.Id);  
        }
        Set<Id> allManagersClone = allManagers.Clone();
        allManagersClone.removeAll(allUsersWithManagers);
        System.assert(allManagersClone.size() >=1,'Boss user not found' );
        Id BossUserId;
        user bossUser; 
        for (Id currId : allManagersClone) {
         bossUser =  [Select Id,Name,CBBudgetManager__c from user where Id= :currId];  
         BossUserId = currId;
         break;
        }
        List <user> firstLevelMeneger = [Select Id,Name,CBBudgetManager__c from user where  CBBudgetManager__c = :BossUserId 
                                           and id in :allManagers limit 1];
        System.assert(firstLevelMeneger.size() ==1,'First Level Manager not found' );
                
        Id firstLevelMenegerId =firstLevelMeneger[0].Id; 
        
        List <user> secondLevelMeneger = [Select Id,Name,CBBudgetManager__c from user where  CBBudgetManager__c = :firstLevelMenegerId 
                                          and id in :allUsersWithManagers limit 1];
        
        System.assert(secondLevelMeneger.size() ==1,'Second Level Manager not found' );
        Id secondLevelMenegerId =secondLevelMeneger[0].Id; 
        
        Id dimensionId = [select Id from cb4__CBDimension__c where Name = 'Budget App'].Id;
        
         
        cb4__CBTag__c bossBudget0 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'consolidatedBudget_0_level', cb4__Status__c = 'Open',ownerId= BossUserId);
        insert bossBudget0;
        cb4__CBTag__c bossBudget1 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'BossBudget_1_level', cb4__Status__c = 'Open',ownerId= BossUserId , cb4__Tag1__c = bossBudget0.Id);
        insert bossBudget1;
        cb4__CBTag__c bossBudget2 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'BossBudget_2_level', cb4__Status__c = 'Open',ownerId= BossUserId , cb4__Tag1__c = bossBudget1.Id);
        cb4__CBTag__c manageBudget1 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'first level manager consolidated', cb4__Status__c = 'Open',ownerId= firstLevelMenegerId , cb4__Tag1__c = bossBudget1.Id);
        insert new list<cb4__CBTag__c>{bossBudget2,manageBudget1};

        cb4__CBTag__c manageBudget2 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'first level manager', cb4__Status__c = 'Open',ownerId= firstLevelMenegerId , cb4__Tag1__c = manageBudget1.Id);
        cb4__CBTag__c planerBudget1 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'Second level planer consolidated', cb4__Status__c = 'Open',ownerId= secondLevelMenegerId , cb4__Tag1__c = manageBudget1.Id);
        insert new list<cb4__CBTag__c>{manageBudget2,planerBudget1};
        cb4__CBTag__c planerBudget2 = 
            new cb4__CBTag__c(cb4__Dimension__c = dimensionId , Name = 'Second level planer ', cb4__Status__c = 'Open',ownerId= secondLevelMenegerId , cb4__Tag1__c = planerBudget1.Id);
        insert planerBudget2;
        System.runas(firstLevelMeneger[0]) { 
           CBApprovalProcessTMS.getTagById(manageBudget1.Id); 
           CBApprovalProcessTMS.getTagById(manageBudget2.Id); 
           CBApprovalProcessTMS.getTagById(planerBudget1.Id);
           CBApprovalProcessTMS.getTagById(planerBudget2.Id); 
        }
        
        System.runas(secondLevelMeneger[0]) { 
           CBApprovalProcessTMS.getTagById(planerBudget1.Id);
           CBApprovalProcessTMS.getTagById(planerBudget2.Id); 
        }
        
        System.runas(bossUser) { 
           CBApprovalProcessTMS.getTagById(bossBudget0.Id); 
           CBApprovalProcessTMS.getTagById(bossBudget1.Id); 
           CBApprovalProcessTMS.getTagById(bossBudget2.Id);  
           CBApprovalProcessTMS.getTagById(planerBudget1.Id); 
           
           CBApprovalProcessTMS.getBudgetsListToApprove();
            Map<String, String> parametersObject = new  Map<String, String> {
              'appId' =>  bossBudget0.Id ,
              'userId' => bossUser.Id,
              'designatedApproverId'=> bossUser.Id    
            };
           CBApprovalProcessTMS.submitTag(parametersObject);
           CBApprovalProcessTMS.getTagById(bossBudget0.Id);  
           CBApprovalProcessTMS.approveTag(bossBudget0.Id, bossUser.Id);
           CBApprovalProcessTMS.getTagById(bossBudget0.Id);  
           CBApprovalProcessTMS.rejectTag(bossBudget0.Id, bossUser.Id);
        }
        
    }

    @isTest static void CBBudgetApplication() {
        if (ec) return;
        cb4__CBTag__c templ = new cb4__CBTag__c(cb4__Dimension__c = dMap.get(cb4.CBConstant.BUDGET_APP_TEMPLATE_DIM), Name = 't');
        insert templ;
        Id perId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period'][0].Id;
        cb4__CBTag__c app = CBBudgetApplication.getNewBudgetAppServer(null);
        System.assert(app != null);
        app.cb4__Tag3__c = BY_ID;
        app.cb4__Tag2__c = templ.Id;
        app.OwnerId = System.UserInfo.getUserId();
        insert app;

        cb4__CBTag__c acc = [SELECT Id FROM cb4__CBTag__c WHERE cb4__Dimension__c = :dMap.get(cb4.CBConstant.ACCOUNT_DIM) LIMIT 1][0];
        cb4.CBRow expRow = new cb4.CBRow();
        expRow.app = app.Id;
        expRow.account = acc.Id;
        expRow.title = 't';
        expRow.ie = 'expense';
        expRow.rowValues = new List<Decimal>{
                1, 1
        };
        expRow.quantityValues = new List<Decimal>{
                1, 1
        };
        expRow.priceValues = new List<Decimal>{
                1, 1
        };
        cb4.CBRow totalRow = new cb4.CBRow();
        totalRow.app = app.Id;
        totalRow.title = 'expense';
        totalRow.ie = 'expense';
        totalRow.rowValues = new List<Decimal>{
                1, 1
        };
        totalRow.quantityValues = new List<Decimal>{
                1, 1
        };
        totalRow.priceValues = new List<Decimal>{
                1, 1
        };
        o = CBBudgetApplication.saveAppTagsServer(app, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test1', cb4__Decimal1__c = 100, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId)
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test2', cb4__Decimal1__c = 100, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId)
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test3', cb4__Decimal1__c = 100, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId)
        });

        List<cb4__CBTag__c> r = CBBudgetApplication.getBudgetAppsServer(app.Id, null);
        r = CBBudgetApplication.getBudgetAppsServer(null, null);

        System.assert(r.size() > 0);

        templ = CBBudgetApplication.getBudgetTemplateServer(r[0].Id);
        System.assertNotEquals(templ, null);
        o = CBBudgetApplication.getBudgetAppDimensionServer();

        o = CBBudgetApplication.getTableHeadersServer(r[0].Id);
        o = CBBudgetApplication.getDownUpSubRowsServer(r[0].Id, 'expense');
        o = CBBudgetApplication.getTopDownSubRowsServer(r[0].Id, 'expense');
        o = CBBudgetApplication.getAccountsServer(r[0].Id);
        o = CBBudgetApplication.getInitialSOServer();
        o = CBBudgetApplication.getFilterCategoriesSOServer();
        o = CBBudgetApplication.getAllChildrenIdsServer(r[0].Id);
        o = CBBudgetApplication.getRowsServer(r[0].Id, null, 'total', null);
        o = CBBudgetApplication.getDownUpSubLines(r[0].Id, 'subsidiary');
        CBBudgetApplication.saveChatServer(r[0].Id, '');
        o = CBBudgetApplication.saveTopDownSubLinesServer(new List<cb4.CBRow>{
                expRow
        });
        o = CBBudgetApplication.getCalcRulesSyntheticLines(r[0].Id, new List<cb4.CBRow>{
                expRow
        }, new List<cb4.CBRow>{
                expRow
        }, null, 1);
        o = CBBudgetApplication.getTagNamesServer(new List<String>{
                BY_ID
        });
        o = CBBudgetApplication.getExtraDimensionsSOServer(r[0].Id);
        o = CBBudgetApplication.getAppLineDimensionsMap(r[0].Id);
        o = CBBudgetApplication.getAppNavigationServer(r[0].Id);
        CBBudgetApplication.calculateAppTotals(r[0], new List<cb4__CBTag__c>());
        CBBudgetApplication.updateApps();
        CBBudgetApplication.cg();
        CBBudgetApplication.insertBackupLog(r[0].Id, 'test', 'test');
        List<cb4__CBLog__c> logList = CBBudgetApplication.getBackupLogList(r[0].Id, null, null);
        o = CBBudgetApplication.getBackupLog(logList[0].Id);

    }

    @isTest static void CBBudgetApplication2() {
        if (ec) return;

        cb4__CBTag__c templ = new cb4__CBTag__c(cb4__Dimension__c = dMap.get(cb4.CBConstant.BUDGET_APP_TEMPLATE_DIM), Name = 't');
        insert templ;
        Id perId = [SELECT Id FROM cb4__CBTag__c WHERE cb4__DimensionName__c = 'Period'][0].Id;
        cb4__CBTag__c app = CBBudgetApplication.getNewBudgetAppServer(null);
        System.assert(app != null);
        app.cb4__Tag3__c = BY_ID;
        app.cb4__Tag2__c = templ.Id;
        app.Name = 'TEST1';
        app.OwnerId = System.UserInfo.getUserId();
        app.Id = CBBudgetApplication.saveAppTagsServer(app, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test11', cb4__Decimal1__c = 101, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'expense')
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test22', cb4__Decimal1__c = 102, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'income')
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test33', cb4__Decimal1__c = 103, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'total')
        });

        CBBudgetApplication.reMapPeriodsIfNeeded(new List<cb4__CBTag__c>{
                new cb4__CBTag__c()
        }, app.Id);

        o = CBBudgetApplication.getCurrentUserInterfaceSettingsListServer('Main');
        o = CBBudgetApplication.getAllAccountsAndDimensionsServer();
        o = CBBudgetApplication.getAppDimensionsMap();
        o = CBBudgetApplication.getPriceQuantityObjectServer();
        o = CBBudgetApplication.getEmployeeRateObjectServer();
        o = CBBudgetApplication.refineStringToId('test');
        o = CBBudgetApplication.getSubLineKey(new cb4__CBTag__c());
        o = CBBudgetApplication.getAccount('test');


        cb4__CBTag__c app2 = CBBudgetApplication.getNewBudgetAppServer(null);
        app2.cb4__Tag1__c = app.Id;
        app2.OwnerId = System.UserInfo.getUserId();
        app2.Name = 'TEST2';
        app2.Id = CBBudgetApplication.saveAppTagsServer(app2, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test1', cb4__Decimal1__c = 101, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'expense')
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test2', cb4__Decimal1__c = 102, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'income')
        }, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test3', cb4__Decimal1__c = 103, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text1__c = 'total')
        });

        List<cb4__CBTag__c> r = CBBudgetApplication.getBudgetAppsServer(null, null);

        System.assert(r.size() > 0);

        o = CBBudgetApplication.getBAListServer(null);
        o = CBBudgetAppTotalService.runRefreshAppsServer(1, new List<String>{
                app2.Id
        });

        CBBudgetApplication.cg();
        //o = CBBudgetApplication.deleteAppServer(r[0].Id);
        o = CBBudgetApplication.voidMethod();
        o = CBBudgetApplication.getAppPeriodsServer(app2.Id);
        o = CBBudgetApplication.getSimpleLineKey(new cb4__CBTag__c(), app2.Id);
        CBBudgetAppTotalService.generateAppNewTotals(new Set<Id>{
                app.Id
        });
        CBBudgetAppTotalService.codGen();
        String s = CBBudgetApplication.getUniqueLabel('PRE', dMap.get(cb4.CBConstant.BUDGET_APP_AMOUNT_DIM));
        CBBudgetApplication.calculateAppTotals(app2, new List<cb4__CBTag__c>{
                new cb4__CBTag__c(Name = 'test1', cb4__Decimal1__c = 101, cb4__Decimal2__c = 200, cb4__Decimal3__c = 300, cb4__Tag3__c = perId, cb4__Text2__c = 'income')
        });

        CBBudgetApplication.deleteAppServer(app.Id);
    }

    // SERVICE METHODS
    static void add(String s) {
        d.add(new cb4__CBDimension__c(Name = s, cb4__PageHeader__c = s + 's'));
    }

}
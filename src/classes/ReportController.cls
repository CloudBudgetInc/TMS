public class ReportController {
    
    public class Cell {
        public String row { get; set; }
        public String col { get; set; }
        public String styleclass { get; set; }
        public String style { get; set; }
        public String value { get; set; }
    }

    public class RLine {
        public List<Cell> Cells { get; set; }
        public String styleclass { get; set; }
        public String style { get; set; }
    }
    public List<RLine> ReportList { get; set; }
    public List<RLine> ReportHeader { get; set; }
    public String StyleClasses { get; set; }
    private List<String> Cities;
    
    private RLine AddLine(String Title, AggregateResult[] ResultQuery, String ResultValue, String RowStyle, String STitleRows, String STitle) {
        
        RLine A = New RLine();
        List<Cell> Line= new List<Cell>();
        Cell Val = new Cell();
        Decimal Tots=0;
        
        If (String.isNotEmpty(RowStyle)) {
            A.style=RowStyle;
        }
        If (String.isNotEmpty(STitle)) {
            Val = new Cell();
            Val.value=STitle;
            Val.style='vertical-align:middle;';
            Val.row=STitleRows;
            Line.add(Val);
        }
        
        Val = new Cell();
        Val.value=Title;
        Val.style='text-align: center;';
        Line.add(Val);
        
        for (String Cty: Cities) {
            Val = new Cell();
            for (AggregateResult ar : ResultQuery) {
                if (Cty==(String)ar.get('TMS_City__c')) {
                    If (ResultValue.containsIgnoreCase('Amount')) {
                        Decimal V=(Decimal)ar.get(ResultValue);
                        Val.value='$ '+ V.SetScale(2);
                    } else {
                        Val.value=String.valueOf(ar.get(ResultValue));
                    }
                    Val.style='text-align: right;';
                    Tots+=(Decimal)ar.get(ResultValue);
                    break;
                }
            }
            Line.add(Val);
        }
        Val = new Cell();
        If (ResultValue.containsIgnoreCase('Amount')) {
            Val.value='$ '+ String.valueOf(Tots);
        } else {
            Val.value=String.valueOf(Tots);
        }
        Val.style='text-align: right;';
        Line.add(Val);
        
        A.cells=Line;
        return(A);
    }        

    private RLine AddHeaderLine(String Title, Integer Col, String Style) {
        RLine H = New RLine();
        Cell Val= new Cell();
        List<Cell> Line = new List<Cell>();
        
        Val.style=Style;
        Val.col=String.valueOf(Col);
        Val.value=Title;
        Line.add(Val);
        
        H.cells=Line;
        return(H);
    }
    
    public ReportController() {
        
        StyleClasses='.b {font-weight:bold; }';
        
        ReportHeader = new List<RLine>();
        ReportList = new List<RLine>();
        
        DateTime CurrentDate=Date.TODAY();

        Date CDate = Date.valueOf(CurrentDate);
        Date CDateL = Date.valueOf(CurrentDate).AddYears(-1);
        
        Date WDate = Date.valueOf(CurrentDate).toStartOfWeek();
        
        Date FDate = Date.valueOf(CurrentDate).toStartOfMonth();
        Date FDateL = Date.valueOf(CurrentDate).toStartOfMonth().AddYears(-1);
       
        DateTime FirstDayofMonth=DateTime.newInstance(Fdate.year(), Fdate.month(),Fdate.day());
        
        List<sobject> ThisWeekZ = [select TMS_City__c, Amount, id, AccountId from opportunity WHERE closedate > :WDate AND closedate <= :CDate AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true ];


        List<AggregateResult> ThisWeek = [select TMS_City__c, Sum(Amount) TotAmount, Count(id) Gifts, COUNT_DISTINCT(AccountId) Donors, Max(Amount) MaxGiftAmount from opportunity WHERE closedate >= :WDate AND closedate <= :CDate AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true group by TMS_City__c];
        List<AggregateResult> ThisMonth= [select TMS_City__c, Sum(Amount) TotAmount, Count(id) Gifts, COUNT_DISTINCT(AccountId) Donors from opportunity where closedate >= :FDate AND closedate <= :CDate AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true group by TMS_City__c];
        List<AggregateResult> ThisYear = [select TMS_City__c, Sum(Amount) TotAmount, Count(id) Gifts, COUNT_DISTINCT(AccountId) Donors from opportunity where closedate >= 2018-04-01 AND closedate <= :CDate AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true group by TMS_City__c];
        List<AggregateResult> LastMonth = [select TMS_City__c, Sum(Amount) TotAmount, Count(id) Gifts, COUNT_DISTINCT(AccountId) Donors from opportunity where closedate >= :FDateL AND closedate <= :CDateL AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true group by TMS_City__c];
        List<AggregateResult> LastYear = [select TMS_City__c, Sum(Amount) TotAmount, Count(id) Gifts, COUNT_DISTINCT(AccountId) Donors from opportunity where closedate >= 2017-04-01 AND closedate <= :CDateL AND Type!='Gift in Kind' AND RecordType.Name='Donation' AND IsClosed=true AND IsWon=true group by TMS_City__c];
        
        Set<String> CitSet = new Set<String>();
        for (AggregateResult ar : LastYear) {
            CitSet.Add((String)ar.get('TMS_City__c'));
        }
        for (AggregateResult ar : ThisYear) {
            CitSet.Add((String)ar.get('TMS_City__c'));
        }        
        Cities = new List<String>(CitSet);
        Cities.sort();
        
        Integer NumberOfColumns=Cities.size()+3;

// ************* Header *************
        ReportHeader.add(AddHeaderLine(CurrentDate.format('MMMMM YYYY'), NumberOfColumns, 'font-weight:bold;background-color: yellow;text-align:center;font-size: large;'));
        ReportHeader.add(AddHeaderLine('Donations from '+ FirstDayofMonth.format('MMM dd') +' to ' + CurrentDate.format('MMM dd'), NumberOfColumns, 'text-align:center;font-weight:bold;font-size: large;'));
        ReportHeader.add(AddHeaderLine('(Cash donations only - does not include GIK donations)', NumberOfColumns, 'text-align:center;font-weight:bold;'));

// ************* Next line *************
        RLine A = New RLine();
        A.styleclass='b';
        A.style='text-align: center;';
        List<Cell> Line= new List<Cell>();
        
        Line.add(new Cell());
        Line.add(new Cell());
        for (String Cty: Cities) {
            Cell Val = new Cell();
            Val.value=Cty;
            Line.add(Val);
        }
        Cell Val = new Cell();
        Val.value='Total';
        Line.add(Val);
        
        A.cells=Line;
        ReportList.add(A);
        
// ************* $ Gifts **************
        ReportList.add(AddLine('This Week', ThisWeek, 'TotAmount','font-weight:bold;background-color: palegreen;text-align: center;','6','$ Gifts'));        
        ReportList.add(AddLine('Largest Gift This Week', ThisWeek, 'MaxGiftAmount','','',''));        
        ReportList.add(AddLine('Month to Date ('+ CDate.year() +')', ThisMonth, 'TotAmount','','',''));        
        ReportList.add(AddLine('Month to Date ('+ CDateL.year() +')', LastMonth , 'TotAmount','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDate.year()+1) +')', ThisYear , 'TotAmount','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDateL.year()+1) +')', LastYear , 'TotAmount','','',''));
// ************* # Gifts *************
        ReportList.add(AddLine('This Week', ThisWeek, 'Gifts','font-weight:bold;background-color: LightSkyBlue;text-align: center;','5','# Gifts'));        
        ReportList.add(AddLine('Month to Date ('+ CDate.year() +')', ThisMonth, 'Gifts','','',''));
        ReportList.add(AddLine('Month to Date ('+ CDateL.year() +')', LastMonth , 'Gifts','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDate.year()+1) +')', ThisYear , 'Gifts','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDateL.year()+1) +')', LastYear , 'Gifts','','',''));
// ************* # Donors *************
        ReportList.add(AddLine('This Week', ThisWeek, 'Donors','font-weight:bold;background-color: NavajoWhite;text-align: center;','5','# Donors'));        
        ReportList.add(AddLine('Month to Date ('+ CDate.year() +')', ThisMonth, 'Donors','','',''));        
        ReportList.add(AddLine('Month to Date ('+ CDateL.year() +')', LastMonth , 'Donors','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDate.year()+1) +')', ThisYear , 'Donors','','',''));
        ReportList.add(AddLine('Fiscal Year to Date ('+ (CDateL.year()+1) +')', LastYear , 'Donors','','',''));
    }

}
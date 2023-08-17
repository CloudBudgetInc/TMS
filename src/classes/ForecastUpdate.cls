public class ForecastUpdate {
    
    public String  CSYear { get; set; }
    public String  CSPeriod { get; set; }
    public Integer CYear { get; set; }
    public Integer CPeriod { get; set; }
    public Integer NYear;
	Public Integer NPeriod;
    
    
	public ForecastUpdate(ApexPages.StandardSetController ctrl) {
        CYear=1;
        CPeriod=1;
    }
    
    public pageReference updateParameterChanges() {
        
        if (CSYear.isNumeric()) {
        	NYear = Integer.valueOf(CSYear);
            CYear=0;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Budget Year contains incorrect value!'));
            CYear=1;
        }

        if (CSPeriod.isNumeric()) {
        	NPeriod = Integer.valueOf(CSPeriod);
            CPeriod=0;
        } else {
          	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period contains incorrect value!'));
            CPeriod=1;
		}
        
        if (NYear<2017||NYear>2025) {
           	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Budget Year contains incorrect value!'));
            CYear=1;
        }
        If (NPeriod<1||NPeriod>12) {
          	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Period contains incorrect value!'));
            CPeriod=1;
        }
        return null;
    }
    
    public pageReference updateBalances() {
        
        Boolean IsLast;
        
		updateParameterChanges();
        if (CYear==1 || CPeriod==1) {
            return null;
        }
        List<c2g__codaBudget__c> Buds = [SELECT Id,c2g__Year__c,c2g__ActualPeriod001__c,c2g__ActualPeriod002__c,c2g__ActualPeriod003__c,c2g__ActualPeriod004__c,c2g__ActualPeriod005__c,c2g__ActualPeriod006__c,c2g__ActualPeriod007__c,c2g__ActualPeriod008__c,c2g__ActualPeriod009__c,c2g__ActualPeriod010__c,c2g__ActualPeriod011__c,c2g__ActualPeriod012__c,Forecast_001__c,Forecast_002__c,Forecast_003__c,Forecast_004__c,Forecast_005__c,Forecast_006__c,Forecast_007__c,Forecast_008__c,Forecast_009__c,Forecast_010__c,Forecast_011__c,Forecast_012__c FROM c2g__codaBudget__c WHERE c2g__Year__r.Name = :CSYear];
        
        List<c2g__codaBudget__c> Budo = new List<c2g__codaBudget__c>();
        
        For (c2g__codaBudget__c Bud: Buds) {
            if (NPeriod>=1) {
                Bud.Forecast_001__c=Bud.c2g__ActualPeriod001__c;
            }
            if (NPeriod>=2) {
                Bud.Forecast_002__c=Bud.c2g__ActualPeriod002__c;
            }
            if (NPeriod>=3) {
                Bud.Forecast_003__c=Bud.c2g__ActualPeriod003__c;
            }
            if (NPeriod>=4) {
                Bud.Forecast_004__c=Bud.c2g__ActualPeriod004__c;
            }
            if (NPeriod>=5) {
                Bud.Forecast_005__c=Bud.c2g__ActualPeriod005__c;
            }
            if (NPeriod>=6) {
                Bud.Forecast_006__c=Bud.c2g__ActualPeriod006__c;
            }
            if (NPeriod>=7) {
                Bud.Forecast_007__c=Bud.c2g__ActualPeriod007__c;
            }
            if (NPeriod>=8) {
                Bud.Forecast_008__c=Bud.c2g__ActualPeriod008__c;
            }
            if (NPeriod>=9) {
                Bud.Forecast_009__c=Bud.c2g__ActualPeriod009__c;
            }
            if (NPeriod>=10) {
                Bud.Forecast_010__c=Bud.c2g__ActualPeriod010__c;
            }
            if (NPeriod>=11) {
                Bud.Forecast_011__c=Bud.c2g__ActualPeriod011__c;
            }
            if (NPeriod>=12) {
                Bud.Forecast_012__c=Bud.c2g__ActualPeriod012__c;
            }
            
            Integer BSize=2500;
            if(Test.isRunningTest()){
				BSize=150;
			}
            if (Budo.Size()<BSize) {
                Budo.Add(Bud);
            } else {
                IsLast= false;
        		ForecastUpdateBatch batch =  new ForecastUpdateBatch(Budo, IsLast);
        		database.executeBatch(batch);
                Budo.Clear();
                if(Test.isRunningTest()){
					Break;
				}
            }
        }
           if (Budo.Size()>0) {
                IsLast=true;
        		ForecastUpdateBatch batch =  new ForecastUpdateBatch(Budo, IsLast);
        		database.executeBatch(batch);
            }

        PageReference np = new PageReference('/a2a/o');
        np.setRedirect(true);
        return np;
    }
}
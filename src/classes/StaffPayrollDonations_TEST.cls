@isTest

public class StaffPayrollDonations_TEST {
    
    @isTest(SeeAllData=true) static void TestStaffDonations() {
        
  
        String TestCSV='Company Name,The Mustard Seed Society,,,,,,,,,,,,,,,\r' +
				'Date Created,9/28/2018,,,,,,,,,,,,,,,\r' +
				',Number,Name,Donation 15th,Donation 31st,Capital Camp Ded 15th,Capital Camp Ded 31st,Start Date,Leave Date,Address,City,Province,Postal Code,Pay Group,Account SF ID,Contact SF ID,Pay Period\r' +
				',2457,"Adebayo Olugbenga ",,,,,3/23/2017,,264 Savannah Road NE ,Calgary,AB,T3J 0W1,Calgary,0013600001pQ5V3AAK,0033600001lz71jAAA,18 - R - 2018-09-21 Calgary\r' +
				',2522,"Adkins, Amanda, Kaye",,50,,,7/10/2017,,18 Heron Crescent,Spruce Grove,AB,T7X 0E9,Edmonton,0013600001immfIAAQ,0033600001e8e3xAAA,18 - R - 2018-09-21 Edmonton\r'+
        		',2109,Canales Flor Edelia,10,,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001pQ5V3AAK,0033600001lz71jAAA,17 - R - 2018-09-06 Calgary\r'+
				',2109,"Canales, Flor Edelia",,10,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001pQ5V3AAK,0033600001lz71jAAA,18 - R - 2018-09-21 Calgary\r'+
				',1698,Chau Anna ,50,,,,3/15/2012,,48 Royal Oak Terrace NW,Calgary,AB,T3G 6A8,Calgary,,0033600001lz71jAAA,17 - R - 2018-09-06 Calgary\r';

        List<npsp__Batch__c> BRL = new List<npsp__Batch__c>();
        
 		npsp__Batch__c BR = new npsp__Batch__c(Name='0101001',Date__c=system.today(),npsp__Object_Name__c='Opportunity');
        insert BR;
        BRL.Add(BR);
 		BR = new npsp__Batch__c(Name='0101002',Date__c=system.today(),npsp__Object_Name__c='Opportunity');
        insert BR;
        BRL.Add(BR);

        Test.startTest();
       
        Test.setCurrentPage(Page.StaffPayrollDonations);
		ApexPages.currentPage().getParameters().put('retURL','/a0M/o');
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(BRL);
       
        
		StaffPayrollDonations BRC= new StaffPayrollDonations(con);
/* test if file doesn't exist */        
        BRC.contentFile=null;
        BRC.uploadFile();
        BRC.contentFile=Blob.valueOf(TestCSV);
        BRC.nameFile='6309o MC.csv';
        BRC.uploadFile();

        BRC.StartRow=2;
        BRC.saveSettings();  
		
        BRC.updateSettingsChanges();
        BRC.createReports();
        system.debug(ApexPages.getMessages());
 		Test.stopTest();        
        
        
     }
    @isTest(SeeAllData=true) static void TestStaffDonations2() {
        

        String TestCSV='Company Name,The Mustard Seed Society,,,,,,,,,,,,,,,\r' +
				'Date Created,9/28/2018,,,,,,,,,,,,,,,\r' +
				',Number,Name,Donation 15th,Donation 31st,Capital Camp Ded 15th,Capital Camp Ded 31st,Start Date,Leave Date,Address,City,Province,Postal Code,Pay Group,Account SF ID,Contact SF ID,Pay Period\r' +
				',2457,Adebayo Olugbenga ,,,,,3/23/2017,,264 Savannah Road NE ,Calgary,AB,T3J 0W1,Calgary,0013600001pQ5V3AAK,0033600001lz71jAAA,18 - R - 2018-09-21 Calgary\r' +
				',2522,Adkins Amanda Kaye,,50,,,7/10/2017,,18 Heron Crescent,Spruce Grove,AB,T7X 0E9,Edmonton,0013600001immfIAAQ,0033600001e8e3xAAA,18 - R - 2018-09-21 Edmonton\r'+
        		',2109,Canales Flor Edelia,10,,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001imzfGAAQ,0033600001e8SCRAA2,17 - R - 2018-09-06 Calgary\r'+
				',2109,Canales Flor Edelia,,10,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001imzfGAAQ,0033600001e8SCRAA2,18 - R - 2018-09-21 Calgary\r'+
				',1698,Chau Anna ,50,,,,3/15/2012,,48 Royal Oak Terrace NW,Calgary,AB,T3G 6A8,Calgary,,0033600001e8!Ac,17 - R - 2018-09-06 Calgary\r';

        List<npsp__Batch__c> BRL = new List<npsp__Batch__c>();
        
 		npsp__Batch__c BR = new npsp__Batch__c(Name='0101001',Date__c=system.today(),npsp__Object_Name__c='Opportunity');
        insert BR;
        BRL.Add(BR);

        
        Test.startTest();
       
        Test.setCurrentPage(Page.StaffPayrollDonations);
		ApexPages.currentPage().getParameters().put('retURL','/a0M/o');
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(BRL);
        
		StaffPayrollDonations BRC= new StaffPayrollDonations(con);

/* test if file doesn't exist */        
        BRC.contentFile=null;
        BRC.uploadFile();
        BRC.contentFile=Blob.valueOf(TestCSV);
        BRC.nameFile='6309o MC.csv';
        BRC.uploadFile();

        BRC.StartRow=2;
        BRC.saveSettings();  
		
        BRC.updateSettingsChanges();
        BRC.createReports();
        system.debug(ApexPages.getMessages());
       
 		Test.stopTest();   
        
     }
    
    @isTest(SeeAllData=true) static void TestStaffDonationsWrongheader() {
        

 
        String TestCSV='Company Name,The Mustard Seed Society,,,,,,,,,,,,,,,\r' +
				'Date Created,9/28/2018,,,,,,,,,,,,,,,\r' +
				',Number,Name,Donation 15th,Donation 31st,Capital Camp Ded 15th,Capital Camp Ded 31st,Start Date,Leave Date,Address,City,Province,Postal Code,Pay Group,Acount SF ID,Cntact SF ID,Pay Period\r' +
				',2457,Adebayo Olugbenga ,,,,,3/23/2017,,264 Savannah Road NE ,Calgary,AB,T3J 0W1,Calgary,0013600001pQ5V3AAK,0033600001lz71jAAA,18 - R - 2018-09-21 Calgary\r' +
				',2522,Adkins Amanda Kaye,,50,,,7/10/2017,,18 Heron Crescent,Spruce Grove,AB,T7X 0E9,Edmonton,0013600001immfIAAQ,0033600001e8e3xAAA,18 - R - 2018-09-21 Edmonton\r'+
        		',2109,Canales Flor Edelia,10,,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001imzfGAAQ,0033600001e8SCRAA2,17 - R - 2018-09-06 Calgary\r'+
				',2109,Canales Flor Edelia,,10,,,8/22/2014,,3039-32A Street SE,Calgary,AB,T2B 0T2,Calgary,0013600001imzfGAAQ,0033600001e8SCRAA2,18 - R - 2018-09-21 Calgary\r'+
				',1698,Chau Anna ,50,,,,3/15/2012,,48 Royal Oak Terrace NW,Calgary,AB,T3G 6A8,Calgary,,0033600001e8cAcAAI,17 - R - 2018-09-06 Calgary\r';

        List<npsp__Batch__c> BRL = new List<npsp__Batch__c>();
        
 		npsp__Batch__c BR = new npsp__Batch__c(Name='0101001',Date__c=system.today(),npsp__Object_Name__c='Opportunity');
        insert BR;
        BRL.Add(BR);

        
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(BRL);
        
		StaffPayrollDonations BRC= new StaffPayrollDonations(con);

/* test if file doesn't exist */        
        BRC.contentFile=null;
        BRC.uploadFile();
        BRC.contentFile=Blob.valueOf(TestCSV);
        BRC.nameFile='6309o MC.csv';
        BRC.uploadFile();

       Test.startTest();
        BRC.StartRow=2;
        BRC.Reportdate=null;
        BRC.saveSettings();  
		
        BRC.updateSettingsChanges();
        BRC.createReports();
        
        BRC.ReportDate=date.today();
        BRC.StartRow=899;
		BRC.updateSettingsChanges();
        
        
 		Test.stopTest();        
        
        
     }    
    
}
/* **************************************************************************
* Test Class: SalesInvoiceTaxCalculationControllerTest
* Created by lv@nubik.ca, 02/01/2017
*
* Purpose/Methods:
* - Unit Test for tax calculation logic
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
private class SalesInvoiceTaxCalculationControllerTest {

	Public static c2g__codaInvoice__c salesInvoice;
	Public static Product2 validProduct;

	public static void generateData()
	{
		Integer numberOfLines = 5;

		SalesInvoiceTaxesSettings__c CS = SalesInvoiceTaxesSettings__c.getOrgDefaults();
		Id productId = [select id from Product2 limit 1].id;
		if(CS == null)
		{
			insert new SalesInvoiceTaxesSettings__c(SetupOwnerId=UserInfo.getOrganizationId(), Tax_Line_Product_Id__c=productId);
		}
        else if(CS.Tax_Line_Product_Id__c == null)
        {
            CS.Tax_Line_Product_Id__c=productId;
            update CS;            
        }
		else
		{
			productId = CS.Tax_Line_Product_Id__c;
		}

		validProduct = [select id from Product2 where Id != :productId limit 1];

		c2g__codaTaxCode__c taxCode = [select  id, name, c2g__TaxModel__c, c2g__IsParent__c,
        	c2g__ChildTaxCode1__c, c2g__ChildTaxCode2__c
            from c2g__codaTaxCode__c limit 1];

		Account a = new Account();
		a.Name = 'Sales Invoice Unit Test';
		a.Type = 'Business';
		a.c2g__CODAOutputVATCode__c = taxCode.id;
		insert a;

		salesInvoice = new c2g__codaInvoice__c();
		salesInvoice.c2g__Account__c = a.id;
		salesInvoice.c2g__InvoiceDate__c = Date.today();
		salesInvoice.c2g__DueDate__c = Date.today().addDays(5);
		salesInvoice.c2g__CustomerReference__c = '0000000';
		salesInvoice.c2g__InvoiceDescription__c = 'TEST INVOICE';
		insert 	salesInvoice;

		list<c2g__codaInvoiceLineItem__c> lines = new list<c2g__codaInvoiceLineItem__c>();
		for(Integer z= 0; z< numberOfLines; z++)
		{
			c2g__codaInvoiceLineItem__c line = new c2g__codaInvoiceLineItem__c();
			line.c2g__Invoice__c = salesInvoice.Id;
			line.c2g__Quantity__c = 1;
			line.c2g__UnitPrice__c = 500;
			line.c2g__Product__c = validProduct.id;
			lines.add(line);
		}	
		insert lines;
	}

	@isTest(seeALlData=true)
	private static void SalesInvoiceTaxCalculationController_Test() {

		generateData();

		list<c2g__codaInvoiceLineItem__c> sLineItemsPRE = [select id, c2g__UnitPrice__c, c2g__NetValue__c,
			Original_Unit_Price__c, c2g__Product__c
			from c2g__codaInvoiceLineItem__c where c2g__Invoice__c =:salesInvoice.id];

		ApexPages.StandardController sc = new ApexPages.StandardController(salesInvoice);
        SalesInvoiceTaxCalculationController testController = new SalesInvoiceTaxCalculationController(sc);
        
		testController.generateLines();

		map<Id, c2g__codaInvoiceLineItem__c> sLineItemsPOST = new map<Id, c2g__codaInvoiceLineItem__c>([select id, 
			c2g__UnitPrice__c, c2g__NetValue__c,
			Original_Unit_Price__c, c2g__Product__c
			from c2g__codaInvoiceLineItem__c where c2g__Invoice__c =:salesInvoice.id]);

		system.assert(sLineItemsPRE.size()+1 == sLineItemsPOST.size());

		for(c2g__codaInvoiceLineItem__c sLineItem: sLineItemsPRE)
		{
			c2g__codaInvoiceLineItem__c sLineItemUpdated = sLineItemsPOST.get(sLineItem.id);
			system.assert(sLineItem.c2g__UnitPrice__c != sLineItemUpdated.c2g__UnitPrice__c);
		}
		SalesInvoiceHelper.clearSalesInvoiceOriginalUnitPrice = true;

		list<c2g__codaInvoiceLineItem__c> sLineItems = new list<c2g__codaInvoiceLineItem__c>();
		list<Id> sLineIds = new list<Id>();		
		c2g__codaInvoiceLineItem__c lineUpdated = sLineItemsPOST.values().get(0);
		lineUpdated.c2g__UnitPrice__c = 10000;
		sLineItems.add(lineUpdated);

		c2g__codaInvoiceLineItem__c xtraLine = new c2g__codaInvoiceLineItem__c();
		xtraLine.c2g__Invoice__c = salesInvoice.Id;
		xtraLine.c2g__Quantity__c = 1;
		xtraLine.c2g__UnitPrice__c = 500;
		xtraLine.c2g__Product__c = validProduct.id;
		sLineItems.add(xtraLine);

		upsert sLineItems;

		sLineIds.add(lineUpdated.id);
		sLineIds.add(xtraLine.id);

		map<Id, c2g__codaInvoiceLineItem__c> sLineItemsPOST2 = new map<Id, c2g__codaInvoiceLineItem__c>([select id, 
			c2g__UnitPrice__c, c2g__NetValue__c,
			Original_Unit_Price__c, c2g__Product__c
			from c2g__codaInvoiceLineItem__c where id in:sLineIds]);
		for(c2g__codaInvoiceLineItem__c sLineItem: sLineItemsPOST2.values())
		{
			system.assert(sLineItem.Original_Unit_Price__c == null);
		}

	}
}
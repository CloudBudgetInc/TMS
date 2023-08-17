/* **************************************************************************
* Test Class: PayableInvoiceTaxCalculationCtrlTest
* Created by jm@nubik.ca, 02/09/2017
*
* Purpose/Methods:
* - Unit Test for tax calculation logic
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
private class PayableInvoiceTaxCalculationCtrlTest {

	Public static c2g__codaPurchaseInvoice__c payableInvoice;
	Public static c2g__codaGeneralLedgerAccount__c validGLA;

	public static void generateData()
	{
		Integer numberOfLines = 5;


		TaxesSettings__c CS = TaxesSettings__c.getOrgDefaults();
		Id glaId = [select id from c2g__codaGeneralLedgerAccount__c limit 1].id;
		if(CS == null)
		{
			insert new TaxesSettings__c(SetupOwnerId=UserInfo.getOrganizationId(), Expense_Line_Item_GLA__c=glaId);
		}
        else if(CS.Expense_Line_Item_GLA__c == null)
        {
            CS.Expense_Line_Item_GLA__c=glaId;
            update CS;            
        }
		else
		{
			glaId = CS.Expense_Line_Item_GLA__c;
		}

		validGLA = [select id from c2g__codaGeneralLedgerAccount__c where Id != :glaId limit 1];

		c2g__codaTaxCode__c taxCode = [select  id, name, c2g__TaxModel__c, c2g__IsParent__c,
        	c2g__ChildTaxCode1__c, c2g__ChildTaxCode2__c
            from c2g__codaTaxCode__c limit 1];

		Account a = new Account();
		a.Name = 'Sales Invoice Unit Test';
		a.Type = 'Business';
		a.c2g__CODAOutputVATCode__c = taxCode.id;
		insert a;

        Department__c dept = new Department__c();
        dept.Name = 'Unit Test PIN';
        insert dept;

        payableInvoice = new c2g__codaPurchaseInvoice__c();
		payableInvoice.c2g__Account__c = a.id;
		payableInvoice.c2g__InvoiceDate__c = Date.today();
		payableInvoice.c2g__DueDate__c = Date.today().addDays(5);
        payableInvoice.Department__c = dept.id;
		payableInvoice.c2g__InvoiceDescription__c = 'TEST INVOICE';
        payableInvoice.c2g__AccountInvoiceNumber__c = 'qwerty123';
		insert 	payableInvoice;

		list<c2g__codaPurchaseInvoiceExpenseLineItem__c> lines = new list<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
		for(Integer z= 0; z< numberOfLines; z++)
		{
			c2g__codaPurchaseInvoiceExpenseLineItem__c line = new c2g__codaPurchaseInvoiceExpenseLineItem__c();
			line.c2g__PurchaseInvoice__c = payableInvoice.Id;
			line.c2g__NetValue__c = 500;
			line.c2g__GeneralLedgerAccount__c = validGLA.id;
			lines.add(line);
		}	
		insert lines;
	}

	@isTest(seeALlData=true)
	private static void PayableInvoiceTaxCalculationController_Test() {

		generateData();

		list<c2g__codaPurchaseInvoiceExpenseLineItem__c> sLineItemsPRE = [select id, c2g__NetValue__c,
			Original_Net_Value__c
			from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c =:payableInvoice.id];

		ApexPages.StandardController sc = new ApexPages.StandardController(payableInvoice);
        PayableInvoiceTaxCalculationController testController = new PayableInvoiceTaxCalculationController(sc);
        
		testController.generateLines();

		map<Id, c2g__codaPurchaseInvoiceExpenseLineItem__c> sLineItemsPOST = new map<Id, c2g__codaPurchaseInvoiceExpenseLineItem__c>([select id, 
			c2g__NetValue__c, c2g__GeneralLedgerAccount__c,
			Original_Net_Value__c
			from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c =:payableInvoice.id]);

		system.assert(sLineItemsPRE.size()+1 == sLineItemsPOST.size());

		for(c2g__codaPurchaseInvoiceExpenseLineItem__c sLineItem: sLineItemsPRE)
		{
			c2g__codaPurchaseInvoiceExpenseLineItem__c sLineItemUpdated = sLineItemsPOST.get(sLineItem.id);
			system.assert(sLineItem.c2g__NetValue__c != sLineItemUpdated.c2g__NetValue__c);
		}



		PayableInvoiceHelper.clearPayableInvoiceOriginalNetValue = true;

		list<c2g__codaPurchaseInvoiceExpenseLineItem__c> sLineItems = new list<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
		list<Id> sLineIds = new list<Id>();		
		c2g__codaPurchaseInvoiceExpenseLineItem__c lineUpdated = sLineItemsPOST.values().get(0);
		lineUpdated.c2g__NetValue__c = 10000;
		sLineItems.add(lineUpdated);

		c2g__codaPurchaseInvoiceExpenseLineItem__c xtraLine = new c2g__codaPurchaseInvoiceExpenseLineItem__c();
		xtraLine.c2g__PurchaseInvoice__c = payableInvoice.Id;
		xtraLine.c2g__NetValue__c = 500;
		xtraLine.c2g__GeneralLedgerAccount__c = validGLA.id;
		sLineItems.add(xtraLine);

		upsert sLineItems;

		sLineIds.add(lineUpdated.id);
		sLineIds.add(xtraLine.id);

		map<Id, c2g__codaPurchaseInvoiceExpenseLineItem__c> sLineItemsPOST2 = new map<Id, c2g__codaPurchaseInvoiceExpenseLineItem__c>([select id, 
			c2g__NetValue__c,
			Original_Net_Value__c
			from c2g__codaPurchaseInvoiceExpenseLineItem__c where id in:sLineIds]);
		for(c2g__codaPurchaseInvoiceExpenseLineItem__c sLineItem: sLineItemsPOST2.values())
		{
			system.assert(sLineItem.Original_Net_Value__c == null);
		}
        
	}
}
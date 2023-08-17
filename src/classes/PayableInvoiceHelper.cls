/* **************************************************************************
* Helper Class: PayableInvoiceHelper
* Created by jm@nubik.ca, 02/09/2017
*
* Purpose/Methods:
* - Support with busniess logic for Payable Invoices
*
* Unit Test:
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class PayableInvoiceHelper {

	public static boolean clearPayableInvoiceOriginalNetValue = true;

	/**
	* @author jm@nubik.ca 
	* @date 01/30/2017
	* @description Generate Sales Invoices Lines for Non ProfitOrgs
	*/
	public static void generateNonProfitTaxes(Id recordId)
	{
		//GetGLA - If there is not GLA defined, the Tax Line cannot be created
		TaxesSettings__c CS = TaxesSettings__c.getOrgDefaults();
		Id glaId = CS.Expense_Line_Item_GLA__c;
		if(glaId == null)
		{
			return;
		}
		//END - GetGLA

		c2g__codaPurchaseInvoice__c payableInvoice = [select id, c2g__Account__c, c2g__Account__r.c2g__CODAOutputVATCode__c,
			c2g__OwnerCompany__c 
			from c2g__codaPurchaseInvoice__c where id = :recordId];
		
		//GetTaxCodes - Get all the tax code, and children taxcodes and realted rates
        map<Id, c2g__codaTaxCode__c> taxCodes = new map<Id, c2g__codaTaxCode__c>([select 
            id, name, c2g__TaxModel__c, c2g__IsParent__c,
        	c2g__ChildTaxCode1__c,
            c2g__ChildTaxCode2__c
            from c2g__codaTaxCode__c where id = :payableInvoice.c2g__Account__r.c2g__CODAOutputVATCode__c]);

        list<Id> allTaxesIds = new list<Id>();
        for(c2g__codaTaxCode__c taxCode: taxCodes.values())
        {
            allTaxesIds.add(taxCode.id);
			if(taxCode.c2g__IsParent__c)
			{
				allTaxesIds.add(taxCode.c2g__ChildTaxCode1__c);
				allTaxesIds.add(taxCode.c2g__ChildTaxCode2__c);
			}
            
        }
        
        list<c2g__codaTaxRate__c> taxRatesAll = [select id, c2g__Rate__c, 
			c2g__TaxCode__c
        	from c2g__codaTaxRate__c where c2g__TaxCode__c in :allTaxesIds order by c2g__StartDate__c desc];
        //Build a map with Tax Rate and the related Code
        map<Id, c2g__codaTaxRate__c> ratesByCode = new map<Id, c2g__codaTaxRate__c>();
        for(c2g__codaTaxRate__c taxRate: taxRatesAll)
        {
            if(ratesByCode.get(taxRate.c2g__TaxCode__c) == null)
            {
    			ratesByCode.put(taxRate.c2g__TaxCode__c, taxRate);
            }
        }
		//END - GetTaxCodes

		c2g__codaTaxCode__c txCode = taxCodes.get(payableInvoice.c2g__Account__r.c2g__CODAOutputVATCode__c);
		//If we have a tax code, begin the calculation
		if(txCode != null)
		{
			//If the TaxCode is Parent we must uset TaxCode1 for the Lines and TaxCode2 for the new Tax Line
			//If the TaxCode is not Parent, we will use half of the Rate for both, existing lines and new tax Line
			boolean isParentTax = txCode.c2g__IsParent__c;
			Decimal taxPercentage = 0;
			if(isParentTax)
			{
				taxPercentage = ratesByCode.get(txCode.c2g__ChildTaxCode1__c).c2g__Rate__c;
			}
			else
			{
				taxPercentage = ratesByCode.get(txCode.id).c2g__Rate__c / 2;
			}

			taxPercentage = taxPercentage/100;
			system.debug('PayableInvoiceHelper generateNonProfitTaxes taxPercentage ' + taxPercentage);
			system.debug('PayableInvoiceHelper generateNonProfitTaxes isParentTax ' + isParentTax);

			//Lets get and update all the Line Items
			list<c2g__codaPurchaseInvoiceExpenseLineItem__c> lineItems = [select id, c2g__NetValue__c,
				Original_Net_Value__c, c2g__GeneralLedgerAccount__c
				from c2g__codaPurchaseInvoiceExpenseLineItem__c where c2g__PurchaseInvoice__c =:recordId];
			
			//We need to get the total before applying taxes
			Decimal totalBeforeTax = 0;
			list<c2g__codaPurchaseInvoiceExpenseLineItem__c> updatedLines = new list<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
			list<c2g__codaPurchaseInvoiceExpenseLineItem__c> toDeleteLines = new list<c2g__codaPurchaseInvoiceExpenseLineItem__c>();
			for(c2g__codaPurchaseInvoiceExpenseLineItem__c lineItem: lineItems)
			{

				if(lineItem.c2g__GeneralLedgerAccount__c == glaId)
				{
					toDeleteLines.add(lineItem);
					continue;
				}
				Decimal unitPrice = lineItem.c2g__NetValue__c;
				//If we have a value in the field Original Unit Price, it means we already did a tax calculation
				//and we must use the original value, just in case the Tax Code changes this way we will use the original
				//value all the time
				if(lineItem.Original_Net_Value__c != null)
				{
					unitPrice = lineItem.Original_Net_Value__c;
				}
				else
				{
					//If we don't have a value that menas it's the first time, we must store the value before changing it
					lineItem.Original_Net_Value__c = lineItem.c2g__NetValue__c;
				}

				totalBeforeTax += unitPrice;
				system.debug('PayableInvoiceHelper generateNonProfitTaxes PRE sLineItem.c2g__NetValue__c ' + lineItem.c2g__NetValue__c);
				system.debug('PayableInvoiceHelper generateNonProfitTaxes PRE sLineItem.Original_Net_Value__c ' + lineItem.Original_Net_Value__c);
				system.debug('PayableInvoiceHelper generateNonProfitTaxes unitPrice ' + unitPrice);

                Decimal newValue = unitPrice + (unitPrice * taxPercentage);
				system.debug('PayableInvoiceHelper generateNonProfitTaxes newValue ' + newValue);

				lineItem.c2g__NetValue__c = newValue.setScale(2);
				updatedLines.add(lineItem);

				system.debug('PayableInvoiceHelper generateNonProfitTaxes POST sLineItem.c2g__NetValue__c ' + lineItem.c2g__NetValue__c);
				system.debug('PayableInvoiceHelper generateNonProfitTaxes POST sLineItem.Original_Net_Value__c ' + lineItem.Original_Net_Value__c);
			}			
	
			system.debug('PayableInvoiceHelper generateNonProfitTaxes totalBeforeTax ' + totalBeforeTax);

			//Now we generate the new Tax Line, where we will use the TaxCode2 of the TaxCode or half the tax Rate
			c2g__codaPurchaseInvoiceExpenseLineItem__c lineItemTax = new c2g__codaPurchaseInvoiceExpenseLineItem__c();
			lineItemTax.c2g__GeneralLedgerAccount__c = glaId;
			lineItemTax.c2g__PurchaseInvoice__c = recordId;
			lineItemTax.c2g__LineDescription__c = 'Recoverable GST';
			lineItemTax.c2g__OwnerCompany__c = payableInvoice.c2g__OwnerCompany__c;
			if(isParentTax)
			{

				Decimal taxPercentage2 = ratesByCode.get(txCode.c2g__ChildTaxCode2__c).c2g__Rate__c;
				taxPercentage2 = taxPercentage2/100;

                Decimal netValue = totalBeforeTax * taxPercentage2;
				system.debug('PayableInvoiceHelper generateNonProfitTaxes netValue ' + netValue);

				lineItemTax.c2g__NetValue__c = netValue.setScale(2);
			
			}
			else
			{
                Decimal netValue = totalBeforeTax * taxPercentage;
				system.debug('PayableInvoiceHelper generateNonProfitTaxes netValue ' + netValue);

				lineItemTax.c2g__NetValue__c = netValue.setScale(2);
			}
			system.debug('PayableInvoiceHelper generateNonProfitTaxes lineItemTax ' + lineItemTax);

			updatedLines.add(lineItemTax);
		
			upsert updatedLines;
			if(toDeleteLines.size() > 0)
			{
				delete toDeleteLines;
			}
		}
	
	}
 


}
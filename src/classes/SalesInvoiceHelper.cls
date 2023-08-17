/* **************************************************************************
* Helper Class: SalesInvoiceHelper
* Created by jm@nubik.ca, 01/30/2017
*
* Purpose/Methods:
* - Support with busniess logic for Sales Invoices
*
* Unit Test:
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class SalesInvoiceHelper {

	public static boolean clearSalesInvoiceOriginalUnitPrice = true;

	/**
	* @author jm@nubik.ca 
	* @date 01/30/2017
	* @description Generate Sales Invoices Lines for Non ProfitOrgs
	*/
	public static void generateNonProfitTaxes(Id salesInvoiceId)
	{
		//GetProduct - If there is not Product defined, the Tax Line cannot be created
		SalesInvoiceTaxesSettings__c CS = SalesInvoiceTaxesSettings__c.getOrgDefaults();
		Id productId = CS.Tax_Line_Product_Id__c;
		if(productId == null)
		{
			return;
		}
		//END - GetProduct

		c2g__codaInvoice__c salesinvoice = [select id, c2g__Account__c, c2g__Account__r.c2g__CODAOutputVATCode__c,
			c2g__OwnerCompany__c 
			from c2g__codaInvoice__c where id = :salesInvoiceId];
		
		//GetTaxCodes - Get all the tax code, and children taxcodes and realted rates
        map<Id, c2g__codaTaxCode__c> taxCodes = new map<Id, c2g__codaTaxCode__c>([select 
            id, name, c2g__TaxModel__c, c2g__IsParent__c,
        	c2g__ChildTaxCode1__c,
            c2g__ChildTaxCode2__c
            from c2g__codaTaxCode__c where id = :salesinvoice.c2g__Account__r.c2g__CODAOutputVATCode__c]);

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
        	from c2g__codaTaxRate__c where c2g__TaxCode__c in :allTaxesIds];
        //Build a map with Tax Rate and the related Code
        map<Id, c2g__codaTaxRate__c> ratesByCode = new map<Id, c2g__codaTaxRate__c>();
        for(c2g__codaTaxRate__c taxRate: taxRatesAll)
        {
			ratesByCode.put(taxRate.c2g__TaxCode__c, taxRate);
        }
		//END - GetTaxCodes

		c2g__codaTaxCode__c txCode = taxCodes.get(salesinvoice.c2g__Account__r.c2g__CODAOutputVATCode__c);
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
			system.debug('SalesInvoiceHelper generateNonProfitTaxes taxPercentage ' + taxPercentage);
			system.debug('SalesInvoiceHelper generateNonProfitTaxes isParentTax ' + isParentTax);

			//Lets get and update all the Line Items
			list<c2g__codaInvoiceLineItem__c> sLineItems = [select id, c2g__UnitPrice__c, c2g__NetValue__c,
				Original_Unit_Price__c, c2g__Product__c
				from c2g__codaInvoiceLineItem__c where c2g__Invoice__c =:salesInvoiceId];
			
			//We need to get the total before applying taxes
			Decimal totalBeforeTax = 0;
			list<c2g__codaInvoiceLineItem__c> updatedLines = new list<c2g__codaInvoiceLineItem__c>();
			list<c2g__codaInvoiceLineItem__c> toDeleteLines = new list<c2g__codaInvoiceLineItem__c>();
			for(c2g__codaInvoiceLineItem__c sLineItem: sLineItems)
			{
				if(sLineItem.c2g__Product__c == productId)
				{
					toDeleteLines.add(sLineItem);
					continue;
				}
				Decimal unitPrice = sLineItem.c2g__UnitPrice__c;
				//If we have a value in the field Original Unit Price, it means we already did a tax calculation
				//and we must use the original value, just in case the Tax Code changes this way we will use the original
				//value all the time
				if(sLineItem.Original_Unit_Price__c != null)
				{
					unitPrice = sLineItem.Original_Unit_Price__c;
				}
				else
				{
					//If we don't have a value that menas it's the first time, we must store the value before changing it
					sLineItem.Original_Unit_Price__c = sLineItem.c2g__UnitPrice__c;
				}

				totalBeforeTax += unitPrice;
				system.debug('SalesInvoiceHelper generateNonProfitTaxes PRE sLineItem.c2g__UnitPrice ' + sLineItem.c2g__UnitPrice__c);
				system.debug('SalesInvoiceHelper generateNonProfitTaxes PRE sLineItem.Original_Unit_Price__c ' + sLineItem.Original_Unit_Price__c);
				system.debug('SalesInvoiceHelper generateNonProfitTaxes unitPrice ' + unitPrice);

				sLineItem.c2g__UnitPrice__c = unitPrice + (unitPrice * taxPercentage);
				updatedLines.add(sLineItem);

				system.debug('SalesInvoiceHelper generateNonProfitTaxes POST sLineItem.c2g__UnitPrice ' + sLineItem.c2g__UnitPrice__c);
				system.debug('SalesInvoiceHelper generateNonProfitTaxes POST sLineItem.Original_Unit_Price__c ' + sLineItem.Original_Unit_Price__c);
			}			
	
			system.debug('SalesInvoiceHelper generateNonProfitTaxes totalBeforeTax ' + totalBeforeTax);

			//Now we generate the new Tax Line, where we will use the TaxCode2 of the TaxCode or half the tax Rate
			c2g__codaInvoiceLineItem__c sLineItemTax = new c2g__codaInvoiceLineItem__c();
			sLineItemTax.c2g__Product__c = productId;
			sLineItemTax.c2g__Quantity__c = 1;
			sLineItemTax.c2g__Invoice__c = salesInvoiceId;
			sLineItemTax.c2g__LineDescription__c = 'Custom Tax';
			sLineItemTax.c2g__OwnerCompany__c = salesinvoice.c2g__OwnerCompany__c;
			if(isParentTax)
			{
				Decimal taxPercentage2 = ratesByCode.get(txCode.c2g__ChildTaxCode2__c).c2g__Rate__c;
				taxPercentage2 = taxPercentage2/100;
				sLineItemTax.c2g__UnitPrice__c = totalBeforeTax * taxPercentage2;
			
			}
			else
			{
				sLineItemTax.c2g__UnitPrice__c = totalBeforeTax * taxPercentage;
			}
			system.debug('SalesInvoiceHelper generateNonProfitTaxes sLineItemTax ' + sLineItemTax);

			updatedLines.add(sLineItemTax);
		
			upsert updatedLines;
			if(toDeleteLines.size() > 0)
			{
				delete toDeleteLines;
			}
		}
	
	}
 



}
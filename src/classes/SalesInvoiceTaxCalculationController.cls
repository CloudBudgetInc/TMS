/* **************************************************************************
* Controller Class: SalesInvoiceTaxCalculationController
* Created by lv@nubik.ca, 02/01/2017
*
* Purpose/Methods:
* - Controller to call the tax lines calculation
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class SalesInvoiceTaxCalculationController {

	public Id salesInvoiceId{get;set;}
	/**
	* @author jm@nubik.ca 
	* @date 02/01/2017
	* @description Constructor
	*/
	public SalesInvoiceTaxCalculationController(ApexPages.StandardController ctrl)
	{
		salesInvoiceId = ctrl.getId();
	}

	/**
	* @author jm@nubik.ca 
	* @date 02/01/2017
	* @description Call the tax lines calculation if there is an error will display the messages if not redirect
	*	back to the previous page
	*/
	public PageReference generateLines()
	{
		try{
			SalesInvoiceHelper.clearSalesInvoiceOriginalUnitPrice = false;
			SalesInvoiceHelper.generateNonProfitTaxes(salesInvoiceId);
		}catch(Exception e)
		{
            ApexPages.Message myMsg = new ApexPages.Message(
                ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
				
			return null;
		}
		PageReference pr = new PageReference('/' + salesInvoiceId);
		return pr;								
	}

}
/* **************************************************************************
* Controller Class: PayableInvoiceTaxCalculationController
* Created by lv@nubik.ca, 02/09/2017
*
* Purpose/Methods:
* - Controller to call the tax lines calculation
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class PayableInvoiceTaxCalculationController {

	public Id recordId{get;set;}
	/**
	* @author jm@nubik.ca 
	* @date 02/01/2017
	* @description Constructor
	*/
	public PayableInvoiceTaxCalculationController(ApexPages.StandardController ctrl)
	{
		recordId = ctrl.getId();
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
			PayableInvoiceHelper.clearPayableInvoiceOriginalNetValue = false;
			PayableInvoiceHelper.generateNonProfitTaxes(recordId);
		}catch(Exception e)
		{
            ApexPages.Message myMsg = new ApexPages.Message(
                ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
				
			return null;
		}
		PageReference pr = new PageReference('/' + recordId);
		return pr;								
	}

}
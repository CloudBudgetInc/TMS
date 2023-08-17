/* **************************************************************************
* Controller Class: CreateJournalVerifyProjectController
* Created by lv@nubik.ca, 06/13/2017
* Purpose/Methods:
* - Display an error message if the Designation related to the designation 
*   budget doesnt have a Dimension 3
*
* Unit Test: CreateJournalVerifyProjectControllerTest
*
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
public class CreateJournalVerifyProjectController 
{
    private final Opportunity opp;

    /**
     * @author lv@nubik.ca
     * @date 06/13/2017
     * @description Method constructor to initialize the variables
     */
    public CreateJournalVerifyProjectController(ApexPages.StandardController controller)
    {
        Opportunity tmp = (Opportunity)controller.getRecord();
        opp = [Select Id,Create_Journal__c,Account.type, Journal_Lines_To_Create__c, 
                Journal_Header__c from Opportunity where id =: tmp.Id limit 1];
    }

    /**
     * @author lv@nubik.ca
     * @date 06/13/2017
     * @description Get a message if one of the designation projects are null
     * @return Empty if no project is required, otherwise we return a message
     */
    public String getRequiresProject()
    {
        if (opp.Create_Journal__c && opp.Journal_Header__c == null)
        {
            String errorMessage = Label.Journal_Requires_Project;
            if (opp.Journal_Lines_To_Create__c == 0 && (opp.Account.type == 'Government' || 
                    opp.Account.Type == 'Charity/Foundation'))
            {
                return errorMessage;
            }
            List<AggregateResult> hasEmptyProjects = [Select count(Id) from 
                    donation_split__Designation_Budget__c where 
                    donation_split__Opportunity__c =: opp.Id and 
                    ((donation_split__Opportunity__r.Account.Type = 'Government' and 
                    donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c  = true) or 
                    (donation_split__Opportunity__r.Account.Type = 'Charity/Foundation' and 
                    donation_split__Designation__r.Is_GL_Reporting_Code_Between_100_199__c = true) or 
                    donation_split__Opportunity__r.Type = 'DemoCrew' or 
                    donation_split__Opportunity__r.Type = 'DemoCrewPlunge' or 
                    donation_split__Opportunity__r.Type = ' CollegeCrew') and 
                    donation_split__Designation__r.Dimension3_Project__c = null];
            if (hasEmptyProjects[0].get('expr0') == 0)
            {
                errorMessage = '';
                //setOppStatus(opp.Id,'Ready to create');
                return errorMessage;
            }
            //setOppStatus(opp.Id,'Not ready to create');
            return errorMessage;
        }
        return '';
    }
    
   
}
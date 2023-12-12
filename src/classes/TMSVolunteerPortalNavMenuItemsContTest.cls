@isTest
public class TMSVolunteerPortalNavMenuItemsContTest {

    @isTest(seeAllData=true)
    private static void testGetNavigationMenuItems(){
        
        Account a = new Account(name='TEST ACCOUNT');
        insert a;
    
        contact c = new Contact(AccountId = a.id, lastname = 'testLastName');
        insert c;
        
        Profile p = [select id, name from profile where name = 'Volunteer Portal User' limit 1];

        User pu = new User( profileId = p.id, 
                            username='tmsTestUser@noemail.invalid', 
                            email='tmsTestUser@noemail.invalid', 
                            emailencodingkey='UTF-8', 
                            localesidkey = 'en_us', 
                            languagelocalekey='en_US', 
                            timezonesidkey = 'America/Edmonton', 
                            alias='cspu', 
                            lastname='testLastName', 
                            contactId = c.id
                        );
        insert(pu);
        
        System.runAs(pu) {
            NetworkMember membership = [SELECT NetworkID, MemberID FROM NetworkMember
                              WHERE memberID = :pu.id];
            
            System.debug('membership.NetworkId' + membership.NetworkId);
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());

            List<ConnectApi.NavigationMenuItem> nav = TMSVolunteerPortalNavMenuItemsController.getNavigationMenuItems('Default Navigation', 'Live', true , false, membership.NetworkId);

            System.assert(String.valueOf(nav[0]) != null, 'didnt find nav: ' + nav);
        }

    }
}
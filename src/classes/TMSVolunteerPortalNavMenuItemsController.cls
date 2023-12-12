/**
 * A basic controller for fetching NavigationMenuItems.
 */
global with sharing class TMSVolunteerPortalNavMenuItemsController {
    public TMSVolunteerPortalNavMenuItemsController() {}

    /**
     * Performs SOQL query to determine all the children NavigationLinkSet based on the provided menu name.
     * Then uses ConnectApi.NavigationMenu.getCommunityNavigationMenu API to retrieve the NavigationMenuItem's for
     * the navigation menu.
     * See https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_navigation_menu_items.htm
     * 
     * NOTE: a 'Datasource' type menu item can cause an error for a non-commerce LWR site that does not have an associated storefront.
     *
     * NavigationLinkSet contains both Draft and Live versions of the NavigationMenuItems.
     * Use the publishedState enumeration to filter between them.
     * 
     * The (cacheable=true) on the annotation allows this Apex function to be wired in LWC components.
     * 
     * @param navigationLinkSetMasterLabel the menu name (NavigationLinkSet.MasterLabel)
     * @param publishStatus publish status (Live or Draft)
     * @param addHomeMenuItem if true, will include the Home menu item in the data
     * @param includeImageUrl if true, will include any menu item's image URLs in the data; ensure relevant users have permissions to access the Document object (for CustomBrandAsset)
     * @return the navigation menu items
     */
    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.NavigationMenuItem> getNavigationMenuItems(String navigationLinkSetMasterLabel, String publishStatus,
            Boolean addHomeMenuItem, Boolean includeImageUrl, String testNetworkId) {
        System.assert(navigationLinkSetMasterLabel != null);
        String navigationLinkSetDeveloperName = getNavigationLinkSetDeveloperName(navigationLinkSetMasterLabel, testNetworkId);

        System.assert(publishStatus != null);
        System.assert(publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Live.name())
            || publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Draft.name()));
        ConnectApi.PublishStatus publishStatusEnum;
        if (publishStatus.equalsIgnoreCase(ConnectApi.PublishStatus.Draft.name())) {
            publishStatusEnum = ConnectApi.PublishStatus.Draft;
        } else {
            publishStatusEnum = ConnectApi.PublishStatus.Live;
        }

        // Exclude any types that aren't supported for your navigation menu
        List<ConnectApi.NavigationMenuItemType> menuItemsToSkip = new List<ConnectApi.NavigationMenuItemType>{
            ConnectApi.NavigationMenuItemType.Event, // not supported in custom component nav menus
            ConnectApi.NavigationMenuItemType.SystemLink // not supported in nav menus
        };

        String navigationLinkSetId = null; // must provide the API the navigationLinkSetId or navigationLinkSetDeveloperName, but not both

        String networkId = Network.getNetworkId();
        if(networkId == null && testNetworkId != ''){
            networkId = testNetworkId;
        }
        System.assert(networkId != null);

        // Connect API: https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_navigation_menu_items.htm
        ConnectApi.NavigationMenuItemCollection menu = ConnectApi.NavigationMenu.getCommunityNavigationMenu(networkId,
                        navigationLinkSetId, navigationLinkSetDeveloperName, publishStatusEnum,
                        includeImageUrl, addHomeMenuItem, menuItemsToSkip);
        
        List<ConnectApi.NavigationMenuItem> items = menu.menuItems;
        return items;
    }
    
    /**
     * Look up the DeveloperName of the NavigationLinkSet based on the provided
     * MasterLabel (aka menu name) and the NetworkId of the current context.
     * 
     * @param navigationLinkSetMasterLabel the menu name (NavigationLinkSet.MasterLabel)
     * @return the navigation linkset DeveloperName
     */
    private static String getNavigationLinkSetDeveloperName(String navigationLinkSetMasterLabel, String testNetworkId) {
        String networkId = Network.getNetworkId();
        if(networkId == null && testNetworkId != ''){
            networkId = testNetworkId;
        }
        System.assert(networkId != null);
        
        List<NavigationLinkSet> navigationLinkSets = [
            SELECT DeveloperName,Id,MasterLabel,NetworkId 
            FROM NavigationLinkSet
            WHERE NetworkId = :networkId
            AND MasterLabel = :navigationLinkSetMasterLabel
            LIMIT 1
        ];

        System.assert(navigationLinkSets.size() == 1);
        NavigationLinkSet navigationLinkSet = navigationLinkSets.get(0);
        return navigationLinkSet.DeveloperName;
    }
}
import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import isGuest from "@salesforce/user/isGuest";

import getNavigationMenuItems from '@salesforce/apex/TMSVolunteerPortalNavMenuItemsController.getNavigationMenuItems';

/**
 * This is a custom LWC navigation menu component.
 * Make sure the Guest user profile has access to the TMSVolunteerPortalNavMenuItemsContoller apex class.
 */
export default class TmsVolunteerPortalNavigationMenu extends NavigationMixin(LightningElement) {

    /**
     * the label or name of the nav menu linkset (NavigationMenuLinkSet.MasterLabel) exposed by the .js-meta.xml,
     * used to look up the NavigationMenuLinkSet.DeveloperName
     */
     @api linkSetMasterLabel;

     /**
      * the label or name of the nav menu to be served to unauthenticated users
      */
     @api publicLinkSetMasterLabel;

     /**
      * include the Home menu item, if true
      */
     @api addHomeMenuItem = false;
 
     /**
      * include image URLs in the response, if true
      * useful for building a tile menu with images
      */
     @api includeImageUrls = false;

    /**
     * the menu items when fetched by the NavigationItemsController
     */
    @track menuItems = [];

    /**
     * if the items have been loaded
     */
    @track isLoaded = false;

    /**
     * the error if it occurs
     */
    @track error;

    guestUser = isGuest;

    /**
     * the published state of the site, used to determine from which schema to 
     * fetch the NavigationMenuItems
     */
    publishStatus;

    guestuser = isGuest;

    @api
    get menuLabel(){
        if(this.guestUser) {
            return this.publicLinkSetMasterLabel;
        } else {
            return this.linkSetMasterLabel;
        }

    }

    /**
     * Using a custom Apex controller, query for the NavigationMenuItems using the
     * menu name and published state.
     * 
     * The custom Apex controller is wired to provide reactive results. 
     */
    @wire(getNavigationMenuItems, {
        navigationLinkSetMasterLabel: '$menuLabel',
        publishStatus: '$publishStatus',
        addHomeMenuItem: '$addHomeMenuItem',
        includeImageUrl: '$includeImageUrls'
    })
    wiredMenuItems({error, data}) {
        console.debug('menuLabel', this.menuLabel);
        if (data && !this.isLoaded) {
            this.menuItems = data.map((item, index) => {
                return {
                    target: item.actionValue,
                    id: index,
                    label: item.label,
                    type: item.actionType,
                    subMenu: item.subMenu,
                    imageUrl: item.imageUrl,
                    windowName: item.target
                }
            });
            this.error = undefined;
            this.isLoaded = true;
        } else if (error) {
            this.error = error;
            this.menuItems = [];
            this.isLoaded = true;
            console.error(`Navigation menu error: ${JSON.stringify(this.error)}`);
        }
    }

    /**
     * Using the CurrentPageReference, check if the app is 'commeditor'.
     * 
     * If the app is 'commeditor', then the page will use 'Draft' NavigationMenuItems. 
     * Otherwise, it will use the 'Live' schema.
    */
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        const app = currentPageReference && currentPageReference.state && currentPageReference.state.app;
        if (app === 'commeditor') {
            this.publishStatus = 'Draft';
        } else {
            this.publishStatus = 'Live';
        }
    }

    handleHamburgerClick(event) {
        // event.target.
        alert('hamburger click' + event);
    }

    handleLoginClick(event){
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
    }

    handleLogoutClick(event){
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'logout'
            }
        });
    }
}
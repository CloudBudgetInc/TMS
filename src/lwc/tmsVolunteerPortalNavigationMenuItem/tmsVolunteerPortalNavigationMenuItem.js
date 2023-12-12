import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

/**
 * This is an example custom LWC navigation menu item component.
 * This example does not include support for: certain types (submenu, datasource), images, or window name (opening in current or new tab).
 */
export default class TmsVolunteerPortalNavigationMenuItem extends NavigationMixin(LightningElement) {

    /**
     * the NavigationMenuItem from the Apex controller, 
     * contains a label and a target.
     */
    @api item = {};

    @track href = 'javascript:void(0);';

    /**
     * the PageReference object used by lightning/navigation
     */
    pageReference;

    connectedCallback() {
        const { type, target, defaultListViewId } = this.item;
        
        if (!target) {
            // NOTE: if actionValue is null for a Salesforce Object menu item, you may not have created
            // the associated page(s) in your LWR site.
            console.log(`WARNING: Navigation menu item target (originally 'actionValue') is missing for menu item:\n ${JSON.stringify(this.item)}\n\nSkipping. Does the target route exist for the site?`);

            // This URL target may be misconfigured, or may be a parent Menu Label item or a Datasource item
            return;
        }

        // get the correct PageReference object for the menu item type
        if (type === 'InternalLink' || type === 'ExternalLink') {
            // WARNING: Normally you shouldn't use 'standard__webPage' for internal relative targets, but
            // we don't have a way of identifying the PageReference type of an InternalLink URL
            this.pageReference = {
                type: 'standard__webPage',
                attributes: {
                    url: target
                }
            };
        }

        // use the NavigationMixin from lightning/navigation to generate the URL for navigation. 
        if (this.pageReference) {
            this[NavigationMixin.GenerateUrl](this.pageReference)
                .then(url => {
                    this.href = url;
                });
        }
    }

    get label() {
        return this.item.label;
    }

    /**
     * Handle a click on this menu item, open the destination page.
     * 
     * For more menu item click handling tips, see https://developer.salesforce.com/blogs/2020/07/advanced-community-navigation-components
     * But note that we can't use window.open for InternalLink, unless Lightning Locker is disabled for the LWR site.
     * 
     * @param {Object} evt the click event
     */
    handleClick(evt) {
        // use the NavigationMixin from lightning/navigation to perform the navigation.
        evt.stopPropagation();
        evt.preventDefault();
        if (this.pageReference) {
            this[NavigationMixin.Navigate](this.pageReference);
        } else {
            console.error(`Navigation menu type "${this.item.type}" not implemented for item ${JSON.stringify(this.item)}`);
        }
    }

}
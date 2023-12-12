import { LightningElement } from 'lwc';
import LOGO from "@salesforce/resourceUrl/volunteerPortalLogo"
/**
 * @slot hero This is the hero slot
 * @slot content This is the body slot
 * @slot default This is the default slot

 */
export default class TmsVolunteerPortalHeroPageLayout extends LightningElement {
    portalLogo = LOGO;
}
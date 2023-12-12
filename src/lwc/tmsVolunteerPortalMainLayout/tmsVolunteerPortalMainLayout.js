import { LightningElement } from 'lwc';
import LOGO from "@salesforce/resourceUrl/volunteerPortalLogo"
/**
 * @slot logo This is the logo slot
 * @slot header This is the header slot
 * @slot footer This is the footer slot
 * @slot default This is the default slot
 */
export default class TmsVolunteerPortalMainLayout extends LightningElement {
    portalLogo = LOGO;
}
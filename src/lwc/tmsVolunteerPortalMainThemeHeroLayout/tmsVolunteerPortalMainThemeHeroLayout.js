import { LightningElement } from 'lwc';
import LOGO from "@salesforce/resourceUrl/volunteerPortalLogo"

/**
 * @slot logo This is the logo slot
 * @slot header This is the header slot
 * @slot hero This is the hero slot
 * @slot footer This is the footer slot
 * @slot default This is the default slot
 */

export default class TmsVolunteerPortalMainThemeHeroLayout extends LightningElement {
    portalLogo = LOGO;
}
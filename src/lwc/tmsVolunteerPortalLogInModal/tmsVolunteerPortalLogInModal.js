import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class TmsVolunteerPortalLogInModal extends LightningModal {
    @api content;

    handleOkay() {
        this.close('okay');
    }
}
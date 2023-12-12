import { LightningElement } from 'lwc';

export default class TmsVolunteerPortalContactUsPicker extends LightningElement {

    value = '';

    displayCalgary = true;
    displayEdmonton = false;
    displayKamloops = false;
    displayMedicineHat = false;
    displayRedDeer = false;

    get options() {
        return [
            { label: 'choose one...', value: '' },
            { label: 'Calgary', value: 'Calgary' },
            { label: 'Edmonton', value: 'Edmonton' },
            { label: 'Kamloops ', value: 'Kamloops' },
            { label: 'Medicine Hat ', value: 'Medicine Hat' },
            { label: 'Red Deer ', value: 'Red Deer' },
        ];
    }

    handleChange(event) {
        this.value = event.detail.value;
        this.displayNone();
        
        switch(event.detail.value) {
            case "Calgary":
                this.displayCalgary = true;
                break;
            case "Edmonton":
                this.displayEdmonton = true;
                break;
            case "Kamloops":
                this.displayKamloops = true;
                break;
            case "Medicine Hat":
                this.displayMedicineHat = true;
                break;
            case "Red Deer":
                this.displayRedDeer = true;
                break;
            default:
                this.displayCalgary = true;
        }
    }

    displayNone(){
        this.displayCalgary = false;
        this.displayEdmonton = false;
        this.displayKamloops = false;
        this.displayMedicineHat = false;
        this.displayRedDeer = false;
    }

}
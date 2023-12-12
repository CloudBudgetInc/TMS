import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import JOB_OBJECT from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c';
import NAME_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.Name';
import DESCRIPTION_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Description__c';
import ID_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.Id';
import DISPLAY_ON_WEBSITE_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Display_on_Website__c';
import INACTIVE_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Inactive__c';
import LOCATION_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Location__c';
import CITY_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Location_City__c';
import LOCATION_INFORMATION_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Location_Information__c';
import LOCATION_STREET_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Location_Street__c';
import LOCATION_POSTAL_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Location_Zip_Postal_Code__c';
import ONGOING_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Ongoing__c';
import SKILLS_NEEDED_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.GW_Volunteers__Skills_Needed__c';
import REQUIRE_WAIVER_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.Require_Liability_Waiver_Medical_Release__c';

const FIELDS = [ NAME_FIELD, DESCRIPTION_FIELD, ID_FIELD, DISPLAY_ON_WEBSITE_FIELD, INACTIVE_FIELD, LOCATION_FIELD, CITY_FIELD, LOCATION_INFORMATION_FIELD, LOCATION_STREET_FIELD, LOCATION_POSTAL_FIELD, ONGOING_FIELD, SKILLS_NEEDED_FIELD, REQUIRE_WAIVER_FIELD ];

export default class VolunteerJobDetails extends LightningElement {
    @api recordId;

    @track skillComputer;

    @wire(getRecord, {recordId: '$recordId', fields: FIELDS })
    myJob;

    renderedCallback(){

        let skills = this.myJob.data ? getFieldValue(this.myJob.data, SKILLS_NEEDED_FIELD) : "";
        console.log('skills', skills);
        let comp = skills.includes("Computer");
        console.log('comp', comp);
        if(comp) {
            console.log('found comp');
            this.skillComputer = true;
            // return '<lightning-icon slot="media" icon-name="utility:screen"></lightning-icon>';
        } else {
            // return "NOCOMP";
        }

    }

    get jobName() {
        return this.myJob.data ? getFieldValue(this.myJob.data, NAME_FIELD) : "";
    }

    get jobDescription() {
        return this.myJob.data ? getFieldValue(this.myJob.data, DESCRIPTION_FIELD) : "";
    }

    get jobId() {
        return this.myJob.data ? getFieldValue(this.myJob.data, ID_FIELD) : "";
    }

    get jobDisplayOnWebsite() {
        return this.myJob.data ? getFieldValue(this.myJob.data, DISPLAY_ON_WEBSITE_FIELD) : "";
    }

    get jobInactive() {
        return this.myJob.data ? getFieldValue(this.myJob.data, INACTIVE_FIELD) : "";
    }

    get jobProvince() {
        return this.myJob.data ? getFieldValue(this.myJob.data, LOCATION_FIELD) : "";
    }

    get jobCity() {
        return this.myJob.data ? getFieldValue(this.myJob.data, CITY_FIELD) : "";
    }

    get jobLocationInformation() {
        return this.myJob.data ? getFieldValue(this.myJob.data, LOCATION_INFORMATION_FIELD) : "";
    }

    get jobLocationStreet() {
        return this.myJob.data ? getFieldValue(this.myJob.data, LOCATION_STREET_FIELD) : "";
    }

    get jobLocationPostal() {
        return this.myJob.data ? getFieldValue(this.myJob.data, LOCATION_POSTAL_FIELD) : "";
    }

    get jobOngoing() {
        return this.myJob.data ? getFieldValue(this.myJob.data, ONGOING_FIELD) : "";
    }

    get jobSkills() {

        // if(this.myJob.data.fields.GW_Volunteers__Skills_Needed__c.value){
        //     console.log(JSON.stringify(this.myJob.data.fields.GW_Volunteers__Skills_Needed__c.value));
        // }
        // return this.myJob.data ? getFieldValue(this.myJob.data, SKILLS_NEEDED_FIELD) : "";
    }

    get jobRequireWaiver() {
        return this.myJob.data ? getFieldValue(this.myJob.data, REQUIRE_WAIVER_FIELD) : "";
    }

    get cssClass() {
        // return this.jobData.data ? getFieldValue(this.jobData.data, REQUIRE_WAIVER_FIELD) : "";
        if(getFieldValue(this.myJob.data, INACTIVE_FIELD)) {
            console.log(getFieldValue(this.myJob.data, INACTIVE_FIELD));
            return 'unavailable';
        } else {
            console.log(getFieldValue(this.myJob.data, INACTIVE_FIELD));
            return 'available';
        }
    }
}
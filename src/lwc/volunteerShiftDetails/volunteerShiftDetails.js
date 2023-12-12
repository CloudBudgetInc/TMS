import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";

import loginModal from 'c/tmsVolunteerPortalLogInModal';

import strUserId from '@salesforce/user/Id';

import isGuest from "@salesforce/user/isGuest";

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

import SHIFT_ID_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.Id';
import SHIFT_DESCRIPTION_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Description__c';
import SHIFT_DESIRED_NUMBER_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Desired_Number_of_Volunteers__c';
import SHIFT_DURATION_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Duration__c';
import SHIFT_CITY_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Job_Location_City__c';
import SHIFT_NUMBER_NEEDED_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Number_of_Volunteers_Still_Needed__c';
import SHIFT_START_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Start_Date_Time__c';
import SHIFT_NOTES_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__System_Note__c';
import SHIFT_TOTAL_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Total_Volunteers__c';
import SHIFT_NAME_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.Name';
import SHIFT_JOB_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Shift__c.GW_Volunteers__Volunteer_Job__c';

import USER_CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';

const JOBFIELDS = [ NAME_FIELD, DESCRIPTION_FIELD, ID_FIELD, DISPLAY_ON_WEBSITE_FIELD, INACTIVE_FIELD, LOCATION_FIELD, CITY_FIELD, LOCATION_INFORMATION_FIELD, LOCATION_STREET_FIELD, LOCATION_POSTAL_FIELD, ONGOING_FIELD, SKILLS_NEEDED_FIELD, REQUIRE_WAIVER_FIELD ];
const SHIFTFIELDS = [ SHIFT_ID_FIELD,SHIFT_DESCRIPTION_FIELD,SHIFT_DESIRED_NUMBER_FIELD,SHIFT_DURATION_FIELD,SHIFT_CITY_FIELD,SHIFT_NUMBER_NEEDED_FIELD,SHIFT_START_FIELD,SHIFT_NOTES_FIELD,SHIFT_TOTAL_FIELD,SHIFT_NAME_FIELD,SHIFT_JOB_FIELD ];
const USER_FIELDS = [USER_CONTACT_ID_FIELD];

export default class VolunteerShiftDetails extends LightningElement {
    @api recordId;
    
    theJob;
    theShift;
    theUser;

    thisContactId;

    @track theJobId;
    userIsGuest = isGuest;

    registerModalOpen = false;
    errorModalOpen = false;

    modalErrorMessage;
    
    loading = true;

    userId = this.getUserId();

    skillComputer;

    @wire(getRecord, { recordId: "$userId", fields: USER_FIELDS })
    wiredUserRecord({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retrieving the User', this.userId);
        } else if(data) {
            console.debug('User data', JSON.stringify(data));
            this.thisContactId = data?.fields?.ContactId?.value;
            this.loading = false;
        }
    }

    @wire(getRecord, {recordId: "$recordId", fields: SHIFTFIELDS })
    wiredShift({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retrieving the Shift', this.recordId );
        } else if(data) {
            console.debug('Shift Data', JSON.stringify(data));
            this.theShift = data;
            this.theJobId = data?.fields?.GW_Volunteers__Volunteer_Job__c?.value;
            this.loading = false;
            console.debug('JobId', this.theJobId);
        }
    }

    @wire(getRecord, {recordId: "$theJobId", fields: JOBFIELDS })
    wiredJob({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retrieving the Job', this.theJobId);
            console.debug('job error message: ', JSON.stringify(error));
        } else if (data) {
            console.debug('Job Data', JSON.stringify(data));
            this.theJob = data;
            this.loading = false;
        }
    };

    @api get jobName() {
        return this.theJob?.fields?.Name?.value;
    }

    get jobDescription() {
        return this.theJob?.fields?.GW_Volunteers__Description__c?.value;
    }

    get jobId() {
        return this.theJob?.fields?.Id?.value;
    }

    get jobDisplayOnWebsite() {
        return this.theJob?.fields?.GW_Volunteers__Display_on_Website__c?.value;
    }

    get jobInactive() {
        return this.theJob?.fields?.GW_Volunteers__Inactive__c?.value;
    }

    get jobProvince() {
        return this.theJob?.fields?.GW_Volunteers__Location__c?.value;
    }

    get jobCity() {
        return this.theJob?.fields?.GW_Volunteers__Location_City__c?.value;
    }

    get jobLocationInformation() {
        return this.theJob?.fields?.GW_Volunteers__Location_Information__c?.value;
    }

    get jobLocationStreet() {
        return this.theJob?.fields?.GW_Volunteers__Location_Street__c?.value;
    }

    get jobLocationPostal() {
        return this.theJob?.fields?.GW_Volunteers__Location_Zip_Postal_Code__c?.value;
    }

    get jobLocationAddress() {
        return this.jobLocationStreet + ' ' + this.jobCity + ' ' + this.shiftCity + ' ' + this.jobLocationPostal;
    }

    get jobOngoing() {
        return this.theJob?.fields?.GW_Volunteers__Ongoing__c?.value;
    }

    get jobSkills() {
        return this.theJob?.fields?.GW_Volunteers__Skills_Needed__c?.value;
    }

    get jobRequireWaiver() {
        return this.theJob?.fields?.Require_Liability_Waiver_Medical_Release__c?.value;
    }

    get shiftId() {
        return this.theShift?.fields?.Id?.value;
    }

    get shiftStart() {
        return new Date(this.theShift?.fields?.GW_Volunteers__Start_Date_Time__c?.value).toUTCString();
    }

    get shfitStartRaw() {
        return new Date(this.theShift?.fields?.GW_Volunteers__Start_Date_Time__c?.value);
    }

    get shiftEndRaw() {
        return this.shfitStartRaw.setHours(this.shfitStartRaw.getHours()+ this.theShift?.fields?.GW_Volunteers__Duration__c?.value);
    }

    get shiftNeeded() {
        return this.theShift?.fields?.GW_Volunteers__Number_of_Volunteers_Still_Needed__c?.value;
    }

    get shiftDuration() {
        return this.theShift?.fields?.GW_Volunteers__Duration__c?.value;
    }

    get shiftCity() {
        return this.theShift?.fields?.GW_Volunteers__Job_Location_City__c?.value;
    }

    get shiftDesired() {
        return this.theShift?.fields?.GW_Volunteers__Desired_Number_of_Volunteers__c?.value;
    }

    get shiftTotal() {
        if (this.theShift?.fields?.GW_Volunteers__Total_Volunteers__c?.value) {
            return this.theShift?.fields?.GW_Volunteers__Total_Volunteers__c?.value;
        } else {
            return '0';
        }
    }

    get shiftDescription() {
        return this.theShift?.fields?.GW_Volunteers__Description__c?.value;
    }

    get cssClass() {
        // return this.jobData.data ? getFieldValue(this.jobData.data, REQUIRE_WAIVER_FIELD) : "";
        // if(getFieldValue(this.myJob.data, INACTIVE_FIELD)) {
        //     console.debug(getFieldValue(this.myJob.data, INACTIVE_FIELD));
        //     return 'unavailable';
        // } else {
        //     console.debug(getFieldValue(this.myJob.data, INACTIVE_FIELD));
        //     return 'available';
        // }
    }

    handleRegisterClicked(event){
        this.modalErrorMessage = '';
        
        const today = new Date();

        console.debug('not logged in details:  theUser-' + this.theUser + '  userIsGuest-' + this.userIsGuest + '  userId-' + this.userId);
        if( this.userIsGuest || (!this.userId && !this.theUser)) {
            this.modalErrorMessage += "It looks like you aren't logged in.";
        }
        if(!this.thisContactId) {
            this.modalErrorMessage += "We can't find your Volunteer Record.";
        } else if(this.shiftStart < today.getDate()) {
            this.modalErrorMessage += "You can't register for a shift that is in the past";
        } else if(this.shiftNeeded == 0) {
            this.modalErrorMessage += "This shift is already full.";
        }

        if(this.modalErrorMessage.length > 0){
            this.openErrorModal();
        } else {
            this.openRegisterModal();
        }
            
    }

    openRegisterModal() {
        console.debug('thisContactId', this.thisContactId);
        this.registerModalOpen=true;
    }
    closeRegisterModal() {
        this.registerModalOpen = false;
    }

    async openErrorModal() {
        //this.errorModalOpen = true;

        const result = await loginModal.open({
            size: 'large',
            description: 'Please login to continue',
            content: 'You need to login before signing up for a shift',
        });
        // if modal closed with X button, promise returns result = 'undefined'
        // if modal closed with OK button, promise returns result = 'okay'
        console.log(result);
    }
    closeErrorModal() {
        this.errorModalOpen = false;
    }

    getUserId(){
        // This is a special check for the dev environment
        // If the current use is the system admin, instead return a test user Id
        if(strUserId == '0053g000000wZF8AAM') {
            // return '003S000001j8BjyIAE';
            console.debug('User intercept. Current Users is system admin. Instead returning info as the test user: 0052300000536y8')
            return '0052300000536y8';
        }else {
            return strUserId;
        }
    }
}
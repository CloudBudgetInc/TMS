import { LightningElement, api, track } from 'lwc';

import { createRecord } from "lightning/uiRecordApi";

import LightningModal from 'lightning/modal';

import HOURS_OBJECT from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c";

import COMMENTS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Comments__c";
import CONTACT_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Contact__c";
import NUMBER_OF_VOLUNTEERS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Number_of_Volunteers__c";
import START_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Start_Date__c";
import STATUS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Status__c";
import JOB_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Volunteer_Job__c";
import SHIFT_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Volunteer_Shift__c";

import CONTACTID_FIELD from "@salesforce/schema/User.ContactId";



import Id from "@salesforce/user/Id";
import isGuest from "@salesforce/user/isGuest";


export default class VolunteerShiftRegisterModal extends LightningModal {
    userId = Id;
    userIsGuest = isGuest;

    loading = false;

    @api shiftId;
    @api shiftStart;
    @api jobName;
    @api jobId;
    @api contactId;

    @api error;
    @api errormsg;

    @track showSuccess = false;
    @track showError = false;

    confirmRegistration(){
        // Create Hours record for User.Id
        // and ShiftId
        // Status Confirmed

        this.loading = true;

        // console.debug('this.contactId', this.contactId);

        const fields = {};
        fields[COMMENTS_FIELD.fieldApiName] = "";
        fields[CONTACT_FIELD.fieldApiName] = this.contactId;
        fields[NUMBER_OF_VOLUNTEERS_FIELD.fieldApiName] = 1;
        fields[START_FIELD.fieldApiName] = new Date(this.shiftStart);
        fields[STATUS_FIELD.fieldApiName] = "Confirmed";
        fields[JOB_FIELD.fieldApiName] = this.jobId;
        fields[SHIFT_FIELD.fieldApiName] = this.shiftId;
        // fields[OWNER_FIELD.fieldApiName] = '0053g000000wZF8AAM';
        

        const recordInput = { apiName: HOURS_OBJECT.objectApiName, fields };

        // console.debug('recordInput', JSON.stringify(recordInput));

        createRecord(recordInput).then((record) => { 
            this.showSuccess = true;
            this.loading = false;
        }).catch(error => {
            this.showError = true;
            // console.debug('Error Message', error.body.message, 'Guest', this.userIsGuest);
            // console.debug('error', JSON.stringify(error));
            // console.debug(JSON.stringify(fields));
            this.loading = false;
        })
    }

    closeModal(){
        this.dispatchEvent(new CustomEvent('closemodal', {
            details: {
                message: 'Close this modal'
        }
        }));
    }

}
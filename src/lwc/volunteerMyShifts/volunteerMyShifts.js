import { LightningElement, api, track, wire } from 'lwc';

import getContactHoursList from '@salesforce/apex/TMSVolunteerPortalController.getContactHoursList';

import strUserId from '@salesforce/user/Id';

import isGuest from "@salesforce/user/isGuest";

import { getRecord, getRecords, updateRecord } from 'lightning/uiRecordApi';

import USER_CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';
import CONTACT_ID_FIELD from "@salesforce/schema/Contact.Id";

import HOURS_ID_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.Id";
import HOURS_COMMENTS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Comments__c";
import HOURS_CONTACT_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Contact__c";
import HOURS_END_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__End_Date__c";
import HOURS_FULL_NAME_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Full_Name__c";
import HOURS_HOURS_WORKED_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Hours_Worked__c";
import HOURS_NUMBER_OF_VOLUNTEERS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Number_of_Volunteers__c";
import HOURS_PLANNED_START_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Planned_Start_Date_Time__c";
import HOURS_START_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Shift_Start_Date_Time__c";
import HOURS_START_DATE_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Start_Date__c";
import HOURS_STATUS_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Status__c";
import HOURS_JOB_FIELD from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Volunteer_Job__c";
import HOURS_JOB_NAME from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Volunteer_Job__r.Name";
import HOURS_JOB_DURATION from "@salesforce/schema/GW_Volunteers__Volunteer_Hours__c.GW_Volunteers__Volunteer_Shift__r.GW_Volunteers__Duration__c";

const USER_FIELDS = [USER_CONTACT_ID_FIELD];
const HOURS_FIELDS = [HOURS_COMMENTS_FIELD,HOURS_CONTACT_FIELD,HOURS_END_FIELD,HOURS_FULL_NAME_FIELD,HOURS_HOURS_WORKED_FIELD,HOURS_NUMBER_OF_VOLUNTEERS_FIELD,HOURS_PLANNED_START_FIELD,HOURS_START_FIELD,HOURS_START_DATE_FIELD,HOURS_STATUS_FIELD,HOURS_JOB_FIELD,HOURS_JOB_NAME];

const hoursColumns = [
    { label: 'Id', fieldsName: 'Id', type: 'text' },
    { label: 'Comments', fieldsName: 'GW_Volunteers__Comments__c', type: 'text' },
    { label: 'Contact', fieldsName: 'GW_Volunteers__Contact__c', type: 'text' },
    { label: 'End Date', fieldsName: 'GW_Volunteers__End_Date__c', type: 'text' },
    { label: 'Full Name', fieldsName: 'GW_Volunteers__Full_Name__c', type: 'text' },
    { label: 'Hours Worked', fieldsName: 'GW_Volunteers__Hours_Worked__c', type: 'text' },
    { label: 'Number of Volunteers', fieldsName: 'GW_Volunteers__Number_of_Volunteers__c', type: 'text' },
    { label: 'Planned Start', fieldsName: 'GW_Volunteers__Planned_Start_Date_Time__c', type: 'text' },
    { label: 'Start Time', fieldsName: 'GW_Volunteers__Shift_Start_Date_Time__c', type: 'text' },
    { label: 'startDate', fieldsName: 'GW_Volunteers__Start_Date__c', type: 'text' },
    { label: 'Status', fieldsName: 'GW_Volunteers__Status__c', type: 'text' },
    { label: 'Job', fieldsName: 'GW_Volunteers__Volunteer_Job__c', type: 'text' },
    { label: 'Job Name', fieldsName: 'GW_Volunteers__Volunteer_Job__r.Name', type: 'text' }
    
]

export default class VolunteerMyShifts extends LightningElement {
    @api user;

    @track thisContactId;
    @track totalShifts;

    cancelationDeadline = 1;

    hours=[];
    
    isGuestUser = isGuest;

    loading = true;

    userId = this.getUserId();

    getUserId(){
        // This is a special check for the dev environment
        // If the current use is the system admin, instead return a test user Id
        if(strUserId == '0053g000000wZF8AAM') {
            // return '003S000001j8BjyIAE';
            return '0052300000536y8';
        }else {
            return strUserId;
        }
    }

    @wire(getRecord, { recordId: "$userId", fields: USER_FIELDS })
    wiredUserRecord({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retrieving the User', this.userId);
        } else if(data) {
            this.thisContactId = data?.fields?.ContactId?.value;
            this.loading = false;
        }
    }

    @wire(getContactHoursList, {contactId: '$thisContactId'})
    wiredHours({ error, data }) {
        if(error) {
            console.debug('There was an issue retrieving the Hours records');
        } else if(data) {
            let theHours = data.map((element) => ({
                ...element,
                endTime: this.evalEndTime(element.GW_Volunteers__Shift_Start_Date_Time__c, element.GW_Volunteers__Volunteer_Shift__r?.GW_Volunteers__Duration__c || 2),
                duration: element.GW_Volunteers__Volunteer_Shift__r?.GW_Volunteers__Duration__c || 2,
                displayConfirmButton: this.evalConfirmButton(element.GW_Volunteers__Status__c),
                displayCancelButton: this.evalCancelButton(element.GW_Volunteers__Status__c, element.GW_Volunteers__Shift_Start_Date_Time__c),
                displayConfirmed: this.evalConfirmedBadge(element.GW_Volunteers__Status__c, element.GW_Volunteers__Shift_Start_Date_Time__c),
                displayComplete: this.evalCompleteBadge(element.GW_Volunteers__Status__c),
                displayCanceled: this.evalCanceledBadge(element.GW_Volunteers__Status__c),
                displayNoShow: this.evalNoShowBadge(element.GW_Volunteers__Status__c)

            }));
            this.hours = theHours;
            this.totalShifts = this.hours.length;
        }
    }

    updateHours( recordId, status ){
        this.loading = true;

        const fields = {};
        fields[HOURS_ID_FIELD.fieldApiName] = recordId;
        fields[HOURS_STATUS_FIELD.fieldApiName] = status;

        const recordInput = { fields };

        updateRecord(recordInput)
        .then(() => {
            this.loading = false;
        })
        .catch((error) => {
            console.debug('Error updating the hours record', error.body.message);
            this.loading = false;
        });
    }

    evalEndTime(startTime, duration){
        let utcStart = new Date (startTime);
        return utcStart.setHours(utcStart.getHours() + duration);

    }

    evalConfirmButton(status) {
        if(status == 'Prospect') {
            return true;
        } else {
            return false;
        }
    }
    evalCancelButton(status, startDateString) {
        const today = new Date();
        const startDate = new Date(Date.parse(startDateString));

        let deadlineDate = new Date(startDate);
        deadlineDate.setDate( deadlineDate.getDate() - 1);

        if(status == 'Confirmed' &&  today < deadlineDate) {
            return true;
        } else {
            return false;
        }
    }
    evalConfirmedBadge(status, startDateString) {
        const today = new Date();
        const startDate = new Date(Date.parse(startDateString));

        let deadlineDate = new Date(startDate);
        deadlineDate.setDate( deadlineDate.getDate() - 1);

        if(status == 'Confirmed' &&  today > deadlineDate) {
            return true;
        } else {
            return false;
        }
    }
    
    evalCompleteBadge(status){
        if(status == 'Completed') {
            return true;
        } else {
            return false;
        }
    }
    evalCanceledBadge(status){
        if(status == 'Canceled') {
            return true;
        } else {
            return false;
        }
    }
    evalNoShowBadge(status){
        if(status == 'No-Show') {
            return true;
        } else {
            return false;
        }
    }

    handleCancelClick(event){
        this.updateHours( event.target.dataset.id, 'Canceled' );
    }    
    handleConfirmClick(event){
        this.updateHours( event.target.dataset.id, 'Confirmed' );
    }    

}
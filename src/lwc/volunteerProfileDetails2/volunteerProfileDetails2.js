import { LightningElement, wire, api, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import strUserId from '@salesforce/user/Id';

import isGuest from "@salesforce/user/isGuest";

import CONTACT_OBJECT from "@salesforce/schema/Contact";

import CONTACT_ID_FIELD from "@salesforce/schema/Contact.Id";
import FIRST_NAME_FIELD from "@salesforce/schema/Contact.FirstName";
import LAST_NAME_FIELD from "@salesforce/schema/Contact.LastName";
import STREET_FIELD from '@salesforce/schema/Contact.MailingStreet';
import CITY_FIELD from '@salesforce/schema/Contact.MailingCity';
import STATE_FIELD from '@salesforce/schema/Contact.MailingState';
import POSTAL_FIELD from '@salesforce/schema/Contact.MailingPostalCode';
import COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';
import HOME_PHONE_FIELD from '@salesforce/schema/Contact.HomePhone';
import MOBILE_PHONE_FIELD from '@salesforce/schema/Contact.MobilePhone';
import EMAIL_FIELD from '@salesforce/schema/Contact.Email';
import NOTES_FIELD from '@salesforce/schema/Contact.GW_Volunteers__Volunteer_Notes__c';
import ORGANIZATION_FIELD from '@salesforce/schema/Contact.GW_Volunteers__Volunteer_Organization__c';
import SKILLS_FIELD from '@salesforce/schema/Contact.GW_Volunteers__Volunteer_Skills__c';
import AVAILABILITY_FIELD from '@salesforce/schema/Contact.GW_Volunteers__Volunteer_Availability__c'
import STATUS_FIELD from '@salesforce/schema/Contact.GW_Volunteers__Volunteer_Status__c';
import MEDICAL_FIELD from '@salesforce/schema/Contact.Volunteers_Medical_Conditions__c';
import BACKGROUND_CHECK_FIELD from '@salesforce/schema/Contact.Volunteer_Background_Check_Complete__c';
import LIABILITY_WAIVER_FIELD from '@salesforce/schema/Contact.Volunteer_Current_Liability_Waiver_Med__c';
import TEAM_LEADER_FIELD from '@salesforce/schema/Contact.Volunteer_Team_Leader_Preference__c';
import TMS_CITY_FIELD from '@salesforce/schema/Contact.TMS_City__c';

import USER_CONTACT_ID_FIELD from '@salesforce/schema/User.ContactId';

const CONTACT_FIELDS = [FIRST_NAME_FIELD,LAST_NAME_FIELD,STREET_FIELD,CITY_FIELD,STATE_FIELD,POSTAL_FIELD,COUNTRY_FIELD,HOME_PHONE_FIELD,MOBILE_PHONE_FIELD,EMAIL_FIELD,NOTES_FIELD,ORGANIZATION_FIELD,SKILLS_FIELD,AVAILABILITY_FIELD,STATUS_FIELD,MEDICAL_FIELD,BACKGROUND_CHECK_FIELD,LIABILITY_WAIVER_FIELD,TEAM_LEADER_FIELD,TMS_CITY_FIELD];
const USER_FIELDS = [USER_CONTACT_ID_FIELD];

export default class VolunteerProfileDetails2 extends LightningElement {
    @api myRecordId ='003S000001j8BjyIAE';
    @api contact;
    @api user;

    @track thisContactId;

    isGuestUser = isGuest;

    loading = true;

    userId = this.getUserId();

    displayButtons = false;
    displayNameFields = true;
    editNameFields = false;
    displayAddressFields = true;
    editAddressFields = false;
    displayContactInfoFields = true;
    editContactInfoFields = false;
    displayNotesFields = true;
    editNotesFields = false;
    displaySkillsFields = true;
    editSkillsFields = false;
    displayAvailabilityFields = true;
    editAvailabilityFields = false;
    displayCityFields = true;
    editCityFields = false;

    nameEditButtonDisplay = true;
    addressEditButtonDisplay = true;
    contactInfoEditButtonDisplay = true;
    notesEditButtonDisplay = true;
    skillsEditButtonDisplay = true;
    availibilityEditButtonDisplay = true;
    cityEditButtonDisplay = true;

    saveDisabled = false;

    _street;
    _city;
    _province;
    _postal;
    _country = 'CA';

    _firstName;

    _selectedSkills;
    _selectedAvailability;
    _selectedCity;

    _householdContactRecord;

    nameError;
    addressError;
    phoneError;

    availabilityValues;
    skillsValues;
    cityValues;
    

    countryOptions = [
        { label: 'Canada', value: 'CA' },
        { label: 'United Sates', value: 'US' },
    ];

    countryProvinceMap = {
        US: [
            { label: 'California', value: 'CA' },
            { label: 'Texas', value: 'TX' },
            { label: 'Washington', value: 'WA' },
        ],
        CA: [
            { label: 'Alberta', value: 'AB' },
            { label: 'British Columbia', value: 'BC' },
        ],
    }

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    contactObject({ error, data }) {
        if(error) {
            console.debug('There was an error loading the schema for the Contact Object');
            console.debug('Contact Object Error: ', JSON.stringify(error));
        } else if(data) {
            const rtis = data.recordTypeInfos;
            this._householdContactRecord = Object.keys(rtis).find((rti) => rtis[rti].name === "Household Contact");
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$_householdContactRecord", fieldApiName: SKILLS_FIELD })
    wiredSkillsList({ error, data }) {
        if(error) {
            console.debug('There was an error retrieving the list of available skills');
            console.debug('Skills Picklist Error:  ', JSON.stringify(error));
        } else if (data) {
            this.skillsValues = data?.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$_householdContactRecord", fieldApiName: AVAILABILITY_FIELD })
    wiredAvailabilityList({ error, data }) {
        if(error) {
            console.debug('There was an error retrieving the list of availability');
            console.debug('Availability Picklist Error:  ', JSON.stringify(error));
        } else if (data) {
            this.availabilityValues = data?.values;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$_householdContactRecord", fieldApiName: TMS_CITY_FIELD })
    wiredCityList({ error, data }) {
        if(error) {
            console.debug('There was an error retrieving the list of available Cities');
            console.debug('Communication City Picklist Error: ', JSON.stringify(error));
        } else if (data) {
            this.cityValues = data?.values;
        }
    }

    @wire(getRecord, { recordId: "$userId", fields: USER_FIELDS })
    wiredUserRecord({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retrieving the User', this.userId);
            console.debug('User error:  ', JSON.stringify(error));
        } else if(data) {
            this.thisContactId = data?.fields?.ContactId?.value;
            this.loading = false;
        }
    }

    @wire(getRecord, { recordId: "$thisContactId", fields:CONTACT_FIELDS })
    wiredContactRecord({ error, data }) {
        this.loading = true;
        if(error) {
            console.debug('There was an error retriving the Contact', this.thisContactId);
            console.debug('Contact error:  ', JSON.stringify(error));
        } else if (data) {
            this.contact = data;

            this.nameError = !this.contact?.fields?.FirstName?.value || !this.contact?.fields?.LastName?.value;
            this.addressError = !this.contact?.fields?.MailingStreet?.value || !this.contact?.fields?.MailingCity?.value || !this.contact?.fields?.MailingState?.value || !this.contact?.fields?.MailingPostalCode?.value || !this.contact?.fields?.MailingCountry?.value;
            this.phoneError = !this.contact?.fields?.HomePhone?.value && !this.contact?.fields?.MobilePhone?.value;
            this.loading = false;
        }
    }

    
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

    get contactId() {
        return this.contact?.Id?.value;
    }

    get firstName() {
        return this.contact?.fields?.FirstName?.value;
    }
    
    get lastName() {
        return this.contact?.fields?.LastName?.value;
    }
    
    get street() {
        return this.contact?.fields?.MailingStreet?.value;
    }
    set street(input) {
        this._street = input;
    }

    get city() {
        return this.contact?.fields?.MailingCity?.value;
    }
    set city(input){
        this._city = input;
    }

    get state() {
        return this.contact?.fields?.MailingState?.value;
    }
    set state(input) {
        this._province = input;
    }

    get postal() {
        return this.contact?.fields?.MailingPostalCode?.value;
    }
    set postal(input) {
        this._postal = input
    }

    get country() {       
        return this.contact?.fields?.MailingCountry?.value;
    }
    set country(input) {
        this._country = input;
    }

    get homePhone() {
        return this.contact?.fields?.HomePhone?.value;
    }

    get mobilePhone() {
        return this.contact?.fields?.MobilePhone?.value;
    }

    get email() {
        return this.contact?.fields?.Email?.value;
    }

    get notes() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Notes__c?.value;
    }

    get organization() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Organization__c?.value;
    }

    get displaySkills() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Skills__c?.value;
    }

    get displayAvailability() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Availability__c?.value;
    }

    get skills() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Skills__c?.value?.split(';');
    }

    get availability() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Availability__c?.value?.split(';');
    }

    get status() {
        return this.contact?.fields?.GW_Volunteers__Volunteer_Status__c?.value;
    }

    get medical() {
        return this.contact?.fields?.Volunteers_Medical_Conditions__c?.value;
    }
    get tmsCity() {
        return this.contact?.fields?.TMS_City__c?.value || 'Calgary';
    }

    get displayBackgroundCheckAlert() {
        if(this.contact?.fields?.Volunteer_Background_Check_Complete__c?.value == "Yes - Complete"){
            return false;
        } else {
            return true;
        }
    }
    
    get displayLiabilityWaiverAlert() {
        if(this.contact?.fields?.Volunteer_Current_Liability_Waiver_Med__c?.value == true) {
            return false;
        } else {
            return true;
        }
    }
    
    get teamLeader() {
        return this.contact?.fields?.Volunteer_Team_Leader_Preference__c?.value;
    }

    get userContactId() {
        return this.user?.fields?.ContactId.value;
    }

    get getProvinceOptions() {
        return this.countryProvinceMap[this._country];
    }
    get getCountryOptions() {
        return this.countryOptions;
    }

    updateContact(){
        this.loading = true;
        const allValid = [...this.template.querySelectorAll('lightning-input')].reduce(
            (validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            },
            true,
        );

        if (allValid) {
            // Create the recordInput object
            const fields = {};
            fields[CONTACT_ID_FIELD.fieldApiName] = this.thisContactId;
            fields[FIRST_NAME_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='FirstName']",
                ).value;
            fields[LAST_NAME_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='LastName']",
                ).value;
            fields[STREET_FIELD.fieldApiName] = this._street;
            fields[CITY_FIELD.fieldApiName] = this._city;
            fields[STATE_FIELD.fieldApiName] = this._province;
            fields[POSTAL_FIELD.fieldApiName] = this._postal;
            fields[COUNTRY_FIELD.fieldApiName] = this._country;
            fields[HOME_PHONE_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='HomePhone']",
                ).value;
            fields[MOBILE_PHONE_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='MobilePhone']",
                ).value;
            fields[EMAIL_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='Email']",
                ).value;
            fields[NOTES_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='Notes']",
                ).value;
            fields[MEDICAL_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='MedicalConcerns']",
                ).value;    
            fields[ORGANIZATION_FIELD.fieldApiName] = this.template.querySelector(
                "[data-field='GroupName']",
                ).value;
            if(this._selectedSkills){
                fields[SKILLS_FIELD.fieldApiName] = this._selectedSkills.join(';');
            }
            if(this._selectedAvailability){
                fields[AVAILABILITY_FIELD.fieldApiName] = this._selectedAvailability.join(';');
            }
            if(this._selectedCity){
                fields[TMS_CITY_FIELD.fieldApiName] = this._selectedCity;
            }
            // fields[TEAM_LEADER_FIELD.fieldApiName] = this.template.querySelector(
            //     "[data-field='']",
            //     ).value;                
            const recordInput = { fields };
                       
            updateRecord(recordInput)
            .then(() => {
                this.setDisplayMode();
                this.loading = false;
            })
            .catch((error) => {
                console.log('Error', error.body.message);
                this.loading = false;
            });
        } else {
            // The form is not valid
            console.log('Check your input and try again');
            this.loading = false;           
        }
    }

    navigateToLogin() {
        this[ NavigationMixin.Navigate ]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Login'
            }
        });
    }

    handleChange(event) {
        // Display field-level errors and disable button if a name field is empty.
        if (!event.target.value) {
            event.target.reportValidity();
            this.saveDisabled = true;
        } else {
            this.saveDisabled = false;
        }
    }

    handleEditClick(event) {
        this.setEditMode();
    }

    handleSaveClick(event){
        this.updateContact();
    }

    handleCancelClick(event) {
        this.setDisplayMode();
    }

    setDisplayMode(){
        this.displayNameFields = true;
        this.displayButtons = false;
        this.editNameFields = false;
        this.displayAddressFields = true;
        this.editAddressFields = false;
        this.displayContactInfoFields = true;
        this.editContactInfoFields = false;
        this.displayNotesFields = true;
        this.editNotesFields = false;
        this.displaySkillsFields = true;
        this.editSkillsFields = false;
        this.displayAvailabilityFields = true;
        this.editAvailabilityFields = false;
        this.displayCityFields = true;
        this.editCityFields = false;
        
        this.nameEditButtonDisplay = true;
        this.addressEditButtonDisplay = true;
        this.contactInfoEditButtonDisplay = true;
        this.notesEditButtonDisplay = true;
        this.skillsEditButtonDisplay = true;
        this.availibilityEditButtonDisplay = true;
        this.cityEditButtonDisplay = true;
    
    }

    setEditMode(){
        this.displayNameFields = false;
        this.displayButtons = true;
        this.editNameFields = true;
        this.displayAddressFields = false;
        this.editAddressFields = true;
        this.displayContactInfoFields = false;
        this.editContactInfoFields = true;
        this.displayNotesFields = false;
        this.editNotesFields = true;
        this.displaySkillsFields = false;
        this.editSkillsFields = true;
        this.displayAvailabilityFields = false;
        this.editAvailabilityFields = true;
        this.displayCityFields = false;
        this.editCityFields = true;
        
        this.nameEditButtonDisplay = false;
        this.addressEditButtonDisplay = false;
        this.contactInfoEditButtonDisplay = false;
        this.notesEditButtonDisplay = false;
        this.skillsEditButtonDisplay = false;
        this.availibilityEditButtonDisplay = false;
        this.cityEditButtonDisplay = false;

        this._selectedSkills = this.contact?.fields?.GW_Volunteers__Volunteer_Skills__c?.value?.split(';');
        this._selectedAvailability = this.contact?.fields?.GW_Volunteers__Volunteer_Availability__c?.value?.split(';');
    }

    handleAddressChange(event) {
        this.street = event.target.street;
        this._city = event.target.city;
        this._country = event.target.country;
        this._province = event.target.province;
        this._postal = event.target.postalCode;
    }

    handleSkillsChange(event) {
        this._selectedSkills = event.detail.value;
    }

    handleAvailabilityChange(event) {
        this._selectedAvailability = event.detail.value;
    }
    handleCityChange(event) {
        this._selectedCity = event.detail.value;
    }

    processMultiSelect(values) {
        let returnString;
        for(const value in values) {
            returnString += value + ';';
        }
        return returnString;
    }
}
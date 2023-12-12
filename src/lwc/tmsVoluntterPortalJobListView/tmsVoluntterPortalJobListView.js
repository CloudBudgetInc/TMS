import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getRecords } from "lightning/uiRecordApi";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { NavigationMixin } from 'lightning/navigation';
import isGuest from "@salesforce/user/isGuest";

import getJobsList from '@salesforce/apex/TMSVolunteerPortalController.getJobsList';
import getJobDetails from '@salesforce/apex/TMSVolunteerPortalController.getJobDetails';
import getJobShifts from '@salesforce/apex/TMSVolunteerPortalController.getJobShifts2';

import getCityList from '@salesforce/apex/TMSVolunteerPortalController.getCityList';
import getFilteredShifts from '@salesforce/apex/TMSVolunteerPortalController.getFilteredShifts';

import VOLUNTEER_JOB_OBJECT from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c';
import VOLUNTEER_JOB_TYPE_FIELD from '@salesforce/schema/GW_Volunteers__Volunteer_Job__c.Type__c';

export default class TmsVoluntterPortalJobListView extends NavigationMixin(LightningElement) {
    @api isLoading;
    @track typeValues=[];
    @track cityValues=[];
    @api filteredShifts=[];
    
    @track filter= '';
    @track cityFilter= '';

    isGuestuser = isGuest;
    
    loading = true;
    
    @api theJobs = [];

    @wire(getObjectInfo, { objectApiName: VOLUNTEER_JOB_OBJECT })
    objectInfo;

    @wire(getCityList, {})
    wiredCityValues({ error, data }){
        if (error) {
            console.error("City Values Error");
        } else if (data) {
            for(let x in data) {
                if(data[x].GW_Volunteers__Location_City__c){
                    this.cityValues.push({ "value": x, "label":  data[x].GW_Volunteers__Location_City__c});
                }
            };
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$objectInfo.data.defaultRecordTypeId", fieldApiName: VOLUNTEER_JOB_TYPE_FIELD })
    typePicklistValues({ error, data }){
        if (error) {
            console.error("Picklist Values Error");
        } else if (data) {
            this.typeValues = data.values;
        }
    };

    @wire(getFilteredShifts, { jobType: "$filter", city: "$cityFilter", limitSize: 100, offset: 0 })
    wiredShifts({ error, data }){
        if (error) {
            console.error("Error getting shifts");
        } else if (data) {
            this.filteredShifts = data.map((element) => ({
                ...element,
                jobName: element.GW_Volunteers__Volunteer_Job__r.Name,
                newDate: new Date(element.GW_Volunteers__Start_Date_Time__c).toUTCString()
            }));
        }
    }
    
    handleFilterClick(event){
        if(event.target.selected) {
            this.filter = '';
            event.target.selected = false;
            event.target.variant = 'neutral';
        } else {
            let buttons = this.template.querySelectorAll(".filterButton");
            for(let i=0; i<buttons.length; i++){
                buttons[i].selected = false;
                buttons[i].variant = 'neutral';
            }
            this.filter=event.target.dataset.name;
            event.target.selected = true;
            event.target.variant = 'success';    
        }

        
    }

    handleCityClick(event){
        if(event.target.selected) {
            this.cityFilter = '';
            event.target.selected = false;
            event.target.variant = 'neutral';
        } else {
            let buttons = this.template.querySelectorAll(".cityFilterButton");
            for(let i=0; i<buttons.length; i++){
                buttons[i].selected = false;
                buttons[i].variant = 'neutral';
            }
            this.cityFilter = event.target.dataset.name;
            event.target.selected = true;
            event.target.variant = 'success';
        }
    }

    handleConfirmClick(event){
        console.debug("NAVIGATE", event.target.dataset.id);
        
        this [ NavigationMixin.Navigate ]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: 'GW_Volunteers__Volunteer_Shift__c',
                actionName: 'view',
                recordId: event.target.dataset.id
            }
        });
    }
}
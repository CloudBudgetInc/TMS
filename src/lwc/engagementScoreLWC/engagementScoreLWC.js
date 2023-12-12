import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { loadScript } from 'lightning/platformResourceLoader';
//import CHARTJS from '@salesforce/resourceUrl/ChartJS';

// Define the fields to retrieve
const FIELDS = ['Account.Name', 'Account.Account_ID__c', 'Account.Engagement_Score__c', 'Account.Officer_Rating__c', 
                'Account.Account_Soft_Credit_Total__c', 'Account.MonetaryAndRecencyForEngagement__c', 'Account.Frequency__c',
                'Account.Largest_Gift_For_Engagement__c', 'Account.Largest_Soft_Credit_Score__c', 'Account.Account_Volunteering_Score__c'];

// CDN URL for Chart.js
const CHARTJS = 'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.7.0/chart.min.js';

export default class EngagementScoreLWC extends LightningElement {
    @api recordId; // Account Id passed from the Lightning App/Page
    

    // Declare variables to store field values
    accountName;
    accountNumber;
    accountEngagementScore;
    accountOfficerRating;
    accountSoftCredTotal;
    RFMScoreComponent;
    LargestGiftComponent;
    SoftCreditComponent;
    VolunteerScoreComponent;
    
    chart;

    // Use wire service to get the account data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            // Retrieve field values using getFieldValue
            this.accountName = getFieldValue(data, 'Account.Name');
            this.accountNumber = getFieldValue(data, 'Account.Account_ID__c');
            this.accountEngagementScore = getFieldValue(data, 'Account.Engagement_Score__c');
            this.accountOfficerRating = getFieldValue(data, 'Account.Officer_Rating__c');
            this.accountSoftCredTotal = getFieldValue(data, 'Account.Account_Soft_Credit_Total__c');
            this.RFMScoreComponent =  (parseInt(getFieldValue(data, 'Account.MonetaryAndRecencyForEngagement__c')) + (parseInt(getFieldValue(data, 'Account.Frequency__c')) * 20)) * 4;
            this.LargestGiftComponent = parseInt(getFieldValue(data, 'Account.Largest_Gift_For_Engagement__c')) * 4;
            this.SoftCreditComponent = getFieldValue(data, 'Account.Largest_Soft_Credit_Score__c');
            this.VolunteerScoreComponent = getFieldValue(data, 'Account.Account_Volunteering_Score__c');

        } else if (error) {
            console.error('Error loading account data', error);
        }
    }
}
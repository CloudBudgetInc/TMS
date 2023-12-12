import { LightningElement, api, track } from 'lwc';
import getJobShifts from '@salesforce/apex/TMSVolunteerPortalController.getJobShifts2';

import isGuest from "@salesforce/user/isGuest";

const columns = [
    { label: 'Id', fieldName: 'Id', type: 'text'},
    { label: 'Description', fieldName: 'GW_Volunteers__Description__c', type: 'text'},
    { label: 'numberDesired', fieldName: 'GW_Volunteers__Desired_Number_of_Volunteers__c', type: 'text'},
    { label: 'Duration', fieldName: 'GW_Volunteers__Duration__c', type: 'text'},
    { label: 'locationCity', fieldName: 'GW_Volunteers__Job_Location_City__c', type: 'text'},
    { label: 'numberNeeded', fieldName: 'GW_Volunteers__Number_of_Volunteers_Still_Needed__c', type: 'text'},
    { label: 'startTime', fieldName: 'GW_Volunteers__Start_Date_Time__c', type: 'text'},
    { label: 'systemNote', fieldName: 'GW_Volunteers__System_Note__c', type: 'text'},
    { label: 'totalVolunteers', fieldName: 'GW_Volunteers__Total_Volunteers__c', type: 'text'},
    { label: 'Name', fieldName: 'Name', type: 'text'}
];

export default class VolunteerJobShiftsTable extends LightningElement {
    
    @api jobId;
    @api jobName;

    shifts=[];
    error;
    columns = columns;
    rowLimit = 20;
    rowOffset = 0;

    userIsGuest = isGuest;

    @track clickedShiftId;
    @track clickedShiftStart;
    @track totalShifts;

    connectedCallback(){
        this.loadData();
        
    }

    loadData(){
        // console.log("isGuest", this.userIsGuest);
        // console.log('limitSize', this.rowLimit, 'offset', this.rowOffset, 'jobId', this.jobId);
        return getJobShifts({ jobId: this.jobId, limitSize: this.rowLimit, offset: this.rowOffset })
            .then(result => {
                let updatedRecords = [...this.shifts, ...result];
                
                this.shifts = updatedRecords;
                this.totalShifts = this.shifts.length;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                console.log('Data Error', JSON.parse(JSON.stringify(error.body)));
                this.shifts = undefined;
            });
    }

    cleanShifts(){
        console.log('loaded', this.shifts.length);
        newList;

        for(var key in this.shifts) {
            newList.push({value:this.shifts[key], key:key});    
        }
        console.log(newList);
        // this.shifts.forEach(function (singleShift) {
        //     if(!singleShift.GW_Volunteers__Total_Volunteers__c) {
        //         console.log('NO TOTAL', singleShift);
        //         try {
        //             singleShift.push({myVolCount :  0});
        //         } catch(e) {
        //             console.log('caught error', JSON.stringify(e), e);
        //         }
        //     }
        //     console.log('after', singleShift);
        //         })

    }

    loadMoreData(event) {
        // const currentRecord = this.shifts;
        // const { target } = event;
        // target.isLoading = true;

        // this.rowOffset = this.rowOffset + this.rowLimit;
        // this.loadData()
        //     .then(() => {
        //         target.isLoading = false;
        //     })
        let area = this.template.querySelector('.scrollArea');
        let threshold = 2 * event.target.clientHeight;
        let areaHeight = area.clientHeight;
        let scrollTop = event.target.scrollTop;
        console.log('areaHeight', areaHeight, 'scrollTop', scrollTop);
        if(areaHeight - threshold < scrollTop) {
            console.log("LOAD MORE");

            this.rowOffset = this.rowOffset + this.rowLimit;
            target.isLoading = true;
            this.loadData()
                .then(() => {
                    target.isLoading = false;
                })

        }
    }
    
    @track isModalOpen = false;
    openModal(event) {
        if(event.target.label == "Register") {
            this.clickedShiftId = event.target.dataset.id;
            this.clickedShiftStart = event.target.dataset.start;
            this.isModalOpen = true;
        } else if(event.target.label == "Sign In to Register"){
            // OPEN SIGN IN MODAL
        }
    }
    closeModal() {
        this.isModalOpen = false;
    }
    submitDetails() {
        this.isModalOpen = false;
    }


    // maxRows=1000;
    // tableElement;
    // @track dataRow;
    // @track totalRecords;
    // columns = columns;

    // @wire( getJobShifts, {recTotalReturn : 10} )
    // wireMethodCallback({ error, data }) {
    //     if(error) {
    //         console.log('Error');
    //     } else if (data) {
    //         this.dataRow = data;
    //         this.totalRecords = data.length;
    //         console.log('Data', this.dataRow);
    //     }
    // }

    // loadMoreData(event) {
    //     // Display a spinner to signal that data is being loaded
    //     if( event.target ) {
    //         event.target.isLoading = true;
    //     }
    //     this.tableElement = event.target;

    //     // Display 'Loading' when more data is being loaded
    //     this.loadMoreStatus = 'Loading';

    //     getJobShifts( {recToReturn : 10 })
    //         .then((data) => {
    //             const currentData = this.dataRow;
    //             // Appends new data to the end of the table
    //             this.dataRow = this.dataRow.concat(data);
    //             this.loadMoreStatus = '';
    //             this.totalRecords = this.dataRow.length;
    //             if( this.dataRow.length >= this.maxRows ) {
    //                 this.tableElement.enableInfiniteLoading = false;
    //                 this.loadMoreStatus = 'No more data to load';
    //             }

    //             if( this.tableElement ) {
    //                 this.tableElement.isLoading = false;
    //             }
    //         })
    // }
}
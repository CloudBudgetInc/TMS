import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import getShiftsList from '@salesforce/apex/VolunteerPortalController.getShiftsList';
import getSkillsPicklistValues from '@salesforce/apex/VolunteerPortalController.getSkillsPicklistValues';
import getTypesPicklistValues from '@salesforce/apex/VolunteerPortalController.getTypesPicklistValues';
import JAVASCRIPT from '@salesforce/resourceUrl/Javascript';

export default class VolunteerCalendar extends NavigationMixin(LightningElement) {
    @track cityOptions = [{label: 'All', value: 'All'}, 
                            {label: 'Calgary', value: 'Calgary'}, 
                            {label: 'Edmonton', value: 'Edmonton'}, 
                            {label: 'Red Deer', value: 'Red Deer'}, 
                            {label: 'Medicine Hat', value: 'Medicine Hat'}, 
                            {label: 'Kamloops', value: 'Kamloops'}];
    @track typeOptions = [];
    @track skillOptions = [];
    @track typeColorMapping = {};

    predefinedColors = [
        '#1abc9c', '#2ecc71', '#3498db', '#9b59b6', '#34495e',
        '#16a085', '#27ae60', '#2980b9', '#8e44ad', '#2c3e50',
        '#f1c40f', '#e67e22', '#e74c3c', '#ecf0f1', '#95a5a6',
        '#f39c12', '#d35400', '#c0392b', '#bdc3c7', '#7f8c8d'
        // ...add more colors if needed
    ];


    connectedCallback() {
        getSkillsPicklistValues()
        .then(result => {
            this.skillOptions = result.map(skill => {
                return { label: skill, value: skill };
            });
            this.skillOptions.unshift({label: 'All', value: 'All'});
        })
        .catch(error => {
            console.error("Error fetching skill picklist values: ", error);
        });
        getTypesPicklistValues()
            .then(result => {
                this.typeOptions = result.map((type, index) => {
                const color = this.predefinedColors[index % this.predefinedColors.length];
                return { label: type, value: type, color: color };
            });
            this.typeOptions.unshift({ label: 'All', value: 'All', color: '#FFFFFF' });
            })
            .catch(error => {
                console.error("Error fetching type picklist values: ", error);
                if (error.body) {
                    console.error("Detailed error: ", error.body.message);
                } else {
                    console.log(JSON.stringify(error));
                }
            });
    }

    @track selectedCity = 'All';
    @track selectedTypes = [];
    @track selectedSkill = 'All';

    handleCityChange(event) {
        this.selectedCity = event.detail.value;
        this.updateCalendar();
    }

    handleTypeChange(event) {
        const typeValue = event.target.value;
        if (event.target.checked) {
            // Add the type to the selected types array if it's checked
            if (!this.selectedTypes.includes(typeValue)) {
                this.selectedTypes.push(typeValue);
            }
        } else {
            // Remove the type from the selected types array if it's unchecked
            const index = this.selectedTypes.indexOf(typeValue);
            if (index > -1) {
                this.selectedTypes.splice(index, 1);
            }
        }
        this.updateCalendar();
    }

    handleSkillChange(event) {
        this.selectedSkill = event.detail.value;
        this.updateCalendar();
    }

    renderedCallback() {
        Promise.all([
            loadScript(this, JAVASCRIPT + '/fullcalendar.js')
        ]).then(() => {
            this.updateCalendar();
        }).catch(error => {
            console.error("Error loading calendar library", error);
        });
    }

    updateCalendar() {
        const ele = this.template.querySelector('.calendar');
        if (this.calendar) {
            this.calendar.destroy();
        }
        this.calendar = new FullCalendar.Calendar(ele, {
            headerToolbar: { start: 'dayGridMonth,timeGridWeek',
                                center: 'title',
                                end: 'today prev,next' },
            dayMaxEventRows: true,
            initialView: 'dayGridMonth',
            events: (fetchInfo, successCallback, failureCallback) => {

                getShiftsList()
                .then(result => {
                    const events = result.map(shift => {
                        const type = shift.GW_Volunteers__Volunteer_Job__r.Type__c;
                        return {
                            title: shift.GW_Volunteers__Volunteer_Job__r.Name, 
                            start: shift.GW_Volunteers__Start_Date_Time__c,
                            city: shift.GW_Volunteers__Job_Location_City__c,
                            type: shift.GW_Volunteers__Volunteer_Job__r.Type__c,
                            backgroundColor: this.typeColorMapping[type],
                            skill: shift.GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Skills_Needed__c,
                            extendedProps: {
                                GW_Volunteers__Volunteer_Shift__c: shift.Id
                            }
                        };
                    });

                    const filteredEvents = events.filter(event => {
                        const skillArray = event.skill ? event.skill.split(',') : [];
                        return (!this.selectedCity || this.selectedCity === 'All' || event.city === this.selectedCity) &&
                               (!this.selectedTypes.length || this.selectedTypes.includes('All') || this.selectedTypes.includes(event.type)) &&
                               (!this.selectedSkill || this.selectedSkill === 'All' || (event.skill && skillArray.includes(this.selectedSkill)));
                    });

                    successCallback(filteredEvents);
                })
                .catch(error => {
                    console.error("Error fetching shifts: ", error);
                    failureCallback(error);
                });
            },
            eventClick: (info) => {
                const jobId = info.event.extendedProps.GW_Volunteers__Volunteer_Shift__c;
                const targetUrl = `/volunteer-shift/${jobId}`;
        
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: targetUrl,
                    },
                });
        
                info.jsEvent.preventDefault(); // prevent the browser from navigating to the URL specified in the `url` property
            }
        });
        this.calendar.render();
    }

    getRandomColor() {
        const letters = '0123456789ABCDEF';
        let color = '#';
        for (let i = 0; i < 6; i++) {
            color += letters[Math.floor(Math.random() * 16)];
        }
        return color;
    }

    get typesAsArray() {
        return this.typeOptions.map(typeOption => ({
            key: typeOption.value,
            color: `background-color: ${typeOption.color};`
        }));
    }
}
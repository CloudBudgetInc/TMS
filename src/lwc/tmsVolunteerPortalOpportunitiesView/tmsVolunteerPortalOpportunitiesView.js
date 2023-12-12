import { LightningElement } from 'lwc';

export default class TmsVolunteerPortalOpportunitiesView extends LightningElement {
    showCalendar = true;
    showList = false;

    handleShowCalendarClick(event){
        this.showCalendar = true;
        this.showList = false;
        const showCalendarButton = event.target;
        const showListButton = this.template.querySelector('.listButton');

        showCalendarButton.selected = true;
        showListButton.selected = false;

        showCalendarButton.variant = 'success';
        showListButton.variant = 'neutral';
    }
    handleShowListClick(event){
        this.showCalendar = false;
        this.showList = true;
        const showCalendarButton = this.template.querySelector('.calendarButton');
        const showListButton = event.target;

        showCalendarButton.selected = false;
        showListButton.selected = true;

        showCalendarButton.variant = 'neutral';
        showListButton.variant = 'success';
    }

}
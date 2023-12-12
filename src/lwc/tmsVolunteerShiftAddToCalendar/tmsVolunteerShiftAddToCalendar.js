import { LightningElement, api, track } from 'lwc';

export default class TmsVolunteerShiftAddToCalendar extends LightningElement {
    @api title = 'The Mustard Seed Volunteer Shift';
    @api start = 'Sun Jan 1 2023 12:00:00 GMT-0700 (Mountain Standard Time)';
    @api end = '1699992000000';
    @api address = '102 11 Ave SE Calgary T2G 0X5';
    @api description = 'The Mustard Seed Volunteer Shift';
    
    googleurl;
    icalurl;
    yahoo;
    outlook;
    showbuttons = false;
    
    init(){
        let startTime = new Date(this.start).toISOString().replace(/-|:|\.\d+/g, '');
        let startTimeOutlook = new Date(this.start).toISOString().replace('Z', '');

        let endTime = new Date(this.end).toISOString().replace(/-|:|\.\d+/g, '');
        let endTimeOutlook = new Date(this.end).toISOString().replace('Z', '');

        // Google Url
        this.googleurl = encodeURI([
            'https://www.google.com/calendar/render',
            '?action=TEMPLATE',
            '&text=' + (this.title || ''),
            '&dates=' + (startTime || ''),
            '/' + (endTime || ''),
            '&details=' + (this.description || ''),
            '&location=' + (this.address || ''),
            '&sprop=&sprop=name:'
        ].join(''));

        // Outlook or iCal
        this.icalurl = encodeURI(
            'data:text/calendar;charset=utf8,' + [
                'BEGIN:VCALENDAR',
                'VERSION:2.0',
                'BEGIN:VEVENT',
                'DTSTART:' + (startTime || ''),
                'DTEND:' + (endTime || ''),
                'SUMMARY:' + (this.title || ''),
                'DESCRIPTION:' + (this.description || ''),
                'LOCATION:' + (this.address || ''),
                'END:VEVENT',
                'END:VCALENDAR'].join('\n'));

        // Outlook
        this.outlook=encodeURI([
            'https://outlook.live.com/owa/?path=/calendar/action/compose&rru=addevent',
            '&subject=' + (this.title || ''),
            '&startdt=' + (startTimeOutlook || '' ),
            '&enddt=' + (endTimeOutlook || ''),
            '&body=' + (this.description || ''),
            '&location=' + (this.address || ''),
            '&allday=false'
        ].join(''));
        
        this.yahoo = encodeURI([
            'https://calendar.yahoo.com/?v=60',
            '&TITLE=' + 'Volunteering',
            '&ST=' + startTime.replace('Z', ''),
            '&ET=' + endTime.replace('Z', ''),
            '&in_loc=' + ('The Mustard Seed' || '')
        ].join(''));
    }

    buttonhandler(event){
        if(this.showbuttons){
            this.showbuttons = false;
        } else {
            this.init();
            this.showbuttons = true;
        }
    }
}
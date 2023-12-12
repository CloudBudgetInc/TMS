import { LightningElement, api, wire } from 'lwc';
import getCMSContent from '@salesforce/apex/TMSVolunteerPortalController.getCMSContent';
import basePath from '@salesforce/community/basePath';

export default class TmsVolunteerPortalHero extends LightningElement {
    @api overriedInput;
    @api titleInput;
    @api urlInput;
    @api imageAlignInput;
    @api cmsImageInput;

    altText;
    titleText;
    imageAlign;
    get url() {
        return this._url;
    }
    set url(value) {
        this._url = value;
        this.setImageUrl(value);
    }

    _cmsData;
    _hover;
    _isRendered;
    _selected;
    _url;

    @wire(getCMSContent, {
        contentId: '$cmsImageInput',
        page: 0,
        pageSize: 1,
        language: 'en_US',
        filterby: ''
    })
    wiredCMSContent({ data, error }) {
        if( this.overriedInput) {
            this.url = this.urlInput;
            this.titleText = this.titleInput;
            this.imageAlign = this.imageAlignInput;
        } else {
            if (data) {
                console.log('CMS Content Found: ', JSON.stringify(data));
                this._cmsData = data;
                    this.altText = this._cmsData.primaryImage.altText;
                    this.titleText = this._cmsData.imageText.value;
                    this.imageAlign = this._cmsData.vAlignment.value;
                    this.url = 
                        basePath +
                        '/sfsites/c' +
                        this._cmsData.primaryImage.url;
                console.log('url: ', this.url, '  alt: ', this.altText);
            }
            if (error) {
                console.log('CMS Content Error: ', JSON.stringify(error));
            }
        }

    }

    connectedCallback() {
        if( this.overriedInput) {
            this.url = this.urlInput;
            this.titleText = this.titleInput;
            this.imageAlign = this.imageAlignInput;
        } else {

            

        }


    }

    renderedCallback() {
        this.setImageUrl(this._url);
    }
    
    setImageUrl(url){
        // .style.backgroundImage = 'linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url("' + this.urlInput + '")';
        this.template.querySelector(".hero-image").style.backgroundImage = 'linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url("' + url + '")';
        this.template.querySelector(".hero-image").style.backgroundPosition= this.imageAlign;
    }
}
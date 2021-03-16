/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

export default class AddRelationalDiagramContainer extends LightningElement {
    @api recordId
    @track templateName;
    
    handlePopulateTemplateName(event) {
        this.templateName = event.detail;
    }
}
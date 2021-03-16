import { LightningElement, api, track } from 'lwc';

export default class AddRecordTypeMatchingContainer extends LightningElement {
    @api recordId;

    @track recordMatchingName;
    @track processCompleted = false;

    handleRecordMatchingName(event) {
        event.preventDefault();
        this.recordMatchingName = event.detail;
    }

    handleSpinner(event) {
        event.preventDefault();
        this.processCompleted = event.detail;
    }
}
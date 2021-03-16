import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import selectedStories from '@salesforce/apex/UserStoryBundleCtrl.selectedStories';
import getAllMetadata from '@salesforce/apex/UserStoryBundleCtrl.getAllMetadata';
import createBundleRecords from '@salesforce/apex/UserStoryBundleCtrl.createBundleRecords';

import Cancel from '@salesforce/label/c.Cancel';
import User_Story_Bundle from '@salesforce/label/c.User_Story_Bundle';
import CREATE_US_BUNDLE_BUTTON from '@salesforce/label/c.CREATE_US_BUNDLE_BUTTON';

import CUSB_OBJECT from '@salesforce/schema/User_Story_Bundle__c';
import TITLE_FIELD from '@salesforce/schema/User_Story_Bundle__c.Title__c';

import UserStoryValidator from './UserStoryValidator';

export default class UserStoryBundle extends NavigationMixin(LightningElement) {
    @api ids;

    label = {
        Cancel,
        User_Story_Bundle,
        CREATE_US_BUNDLE_BUTTON
    };
    fieldApiName = TITLE_FIELD.fieldApiName;
    objectApiName = CUSB_OBJECT;
    isLoading = false;
    validationErrors = {
        isError: false,
        message: ''
    };
    submitError = {
        isError: false,
        message: ''
    };

    _stories;
    _metadata;
    _fullProfiles;
    _destructiveChanges;
    _error;

    async connectedCallback() {
        try {
            [this._stories, this._metadata, this._fullProfiles, this._destructiveChanges] = await Promise.all([
                selectedStories({ ids: this.ids }),
                getAllMetadata({ ids: this.ids, operations: ['', 'Commit Files', 'Recommit Files'] }),
                getAllMetadata({ ids: this.ids, operations: ['Full Profiles & Permission Sets'] }),
                getAllMetadata({ ids: this.ids, operations: ['Destructive Changes'] })
            ]);
        } catch (e) {
            this._error = e;
        }

        const errors = new UserStoryValidator().execute(this._stories, this._metadata, this._fullProfiles, this._destructiveChanges);
        if (errors.length > 0) {
            this.validationErrors = {
                isError: true,
                message: errors.join('\n')
            };
        }
    }

    async handleSubmit(event) {
        this.isLoading = true;

        event.preventDefault();
        const fields = event.detail.fields;
        try {
            const recordid = await createBundleRecords({
                bundle: fields,
                stories: this._stories,
                metadata: this._metadata,
                fullProfiles: this._fullProfiles,
                destructiveChanges: this._destructiveChanges
            });

            this._navigateToRecordViewPage(recordid);
        } catch (e) {
            this.submitError = {
                isError: true,
                message: e.body.message
            };
        }

        this.isLoading = false;
    }

    closeModal() {
        this._navigateToRecordViewPage('');
    }

    _navigateToRecordViewPage(recordId) {
        const recordEvent = new CustomEvent('navigatetorecord', {
            detail: recordId,
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(recordEvent);
    }
}
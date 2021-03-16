import { LightningElement, track, api } from 'lwc';

import { getDebouncedFunction, handleAsyncError } from 'c/copadocoreUtils';

import findRecords from '@salesforce/apex/CustomLookupComponentHelper.findRecords';

import Remove_Selected_Option from '@salesforce/label/c.Remove_Selected_Option';
import Error_Finding_Records from '@salesforce/label/c.Error_Finding_Records';

export default class CopadocoreLookup extends LightningElement {
    // Start with uppercase because label is already defined and since it has @api
    // and is public we can not remove nor rename it
    Label = {
        Remove_Selected_Option,
        Error_Finding_Records
    };

    modes = {
        FIND: 'findRecords',
        GET: 'getValues'
    };

    @api iconName = 'standard:choice';
    @api mode = this.modes.FIND;
    @api valueMap;
    @api label = '';
    @api tooltipInfo;
    @api placeholder;
    @api required;
    @api filterId;
    @api objectName = 'Account';
    @api searchfield = 'Name';
    @api extraFilterType;
    @api filterFormattingParameters;

    @track records;

    isLoadingData;

    _selectedRecord;
    @api
    get selectedRecord() {
        return this._selectedRecord;
    }
    set selectedRecord(value) {
        this._selectedRecord = value;
    }

    @api
    get disabled() {
        return this._disabled;
    }
    set disabled(value) {
        this._disabled = value;
    }

    get hasTooltip() {
        return this.tooltipInfo ? true : false;
    }

    get isRequired() {
        return this.required ? true : false;
    }

    get hasRecords() {
        return this.records && this.records.length > 0 ? true : false;
    }

    handleChange(event) {
        const searchKey = event.detail.value;
        if (searchKey === '') {
            this.records = [];
            this.isLoadingData = false;
            // Variable available after using getDebouncedFunction
            clearTimeout(this._timeout);
        } else {
            if (this.mode === this.modes.FIND) {
                const callFindRecordsDebounced = getDebouncedFunction(this.callFindRecords, 500);
                callFindRecordsDebounced(this, searchKey);
            } else if (this.mode === this.modes.GET) {
                this.callGetValues(searchKey);
            }
        }
    }

    async callFindRecords(searchKey) {
        if (!searchKey || searchKey.trim().length <= 2) {
            this.records = [];
            return;
        }

        this.isLoadingData = true;
        const safeFindRecords = handleAsyncError(this.findRecords, {
            title: this.Label.Error_Finding_Records
        });
        const queryConfig = {
            searchField: this.searchfield,
            objectName: this.objectName,
            searchKey: searchKey,
            extraFilterType: this.extraFilterType,
            filterFormattingParameters: this.filterFormattingParameters
        };
        const result = await safeFindRecords(this, { queryConfig });
        if (result) {
            this.records = result;
            this.records.forEach((record) => {
                record.Name = record[this.searchfield];
            });
        } else {
            this.records = undefined;
        }
        this.isLoadingData = false;
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    findRecords(self, queryConfig) {
        return findRecords(queryConfig);
    }

    callGetValues(searchKey) {
        if (!searchKey || searchKey.trim().length <= 2) {
            this.records = [];
            return;
        }

        if (this.valueMap) {
            const mapObject = JSON.parse(this.valueMap);
            const objectAPIName = this.getFiltered(mapObject, searchKey);
            this.records = [];
            for (let [key, value] of Object.entries(objectAPIName)) {
                this.records.push({ Name: key, Id: value });
            }
        }
    }

    getFiltered(object, filter) {
        const filtered = Object.keys(object)
            .filter((key) => key.toLowerCase().includes(filter.toLowerCase()))
            .reduce((obj, key) => {
                obj[key] = object[key];
                return obj;
            }, {});
        return filtered;
    }

    handleClick(event) {
        const selectedRecordId = event.currentTarget.dataset.targetId;
        this._selectedRecord = this.records.find((record) => record.Id === selectedRecordId);
        // fire the event with the value of RecordId for the Selected RecordId
        const selectedRecordEvent = new CustomEvent('selectlookupchange', {
            detail: {
                recordId: selectedRecordId,
                recordName: this._selectedRecord.Name,
                filterId: this.filterId
            }
        });
        this.dispatchEvent(selectedRecordEvent);
    }

    handleRemove(event) {
        event.preventDefault();
        this._selectedRecord = undefined;
        this.records = undefined;
        // fire the event with the value of undefined for the Selected RecordId
        const selectedRecordEvent = new CustomEvent('selectlookupchange', {
            detail: {
                recordId: undefined,
                recordName: undefined,
                filterId: this.filterId
            }
        });
        this.dispatchEvent(selectedRecordEvent);
    }
}
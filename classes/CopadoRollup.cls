/**
 * @author Mert YALTI
 */
public class CopadoRollup {
	/**
	*   @SOQL Tempalte tokens
	*        0 : Query Fields
	*        1 : From object
	*        2 : Optional WHERE clause filter/filters
	*        3 : Decition of Group By field
	*/
	static String SOQL_STRING = 'SELECT {0} FROM {1} WHERE {3} in :masterIds {2} GROUP BY {3}';
	//Following 2 line is added in case of multi currency implementation to roll up process
	public static String CURRENCYISOCODENAME = 'CurrencyIsoCode';
	private static Boolean IOrgsMultiCurrency = UserInfo.isMultiCurrencyOrganization();

	/**
	*    Main context of the class
	*    Defining master object,detail object and lookup relationship field
	*    Fields to roll
	*    Defining whereClaus (optional)
	*/
	public class RollUpContext {
		public Schema.Sobjecttype masterObject;
		public Schema.Sobjecttype detailObject;
		public Schema.Describefieldresult relationlookupField;
		public List<RollupSummaryField> rollupFieldsList;

		public String detailWhereClause;

		public rollUpContext(Schema.Sobjecttype m, Schema.Sobjecttype d, Schema.Describefieldresult lf) {
			this(m, d, lf, '');
		}

		public rollUpContext(Schema.Sobjecttype m, Schema.Sobjecttype d, Schema.Describefieldresult lf, String detailWhereClause) {
			this.masterObject = m;
			this.detailObject = d;
			this.relationlookupField = lf;
			this.detailWhereClause = detailWhereClause;
			this.rollupFieldsList = new List<RollupSummaryField>();
		}

		/**
		*    Adds new rollup summary fields to the rollUpContext
		*/
		public void add(RollupSummaryField fld) {
			this.rollupFieldsList.add(fld);
		}
	}
	/**
	*    Exception throwed if Rollup Summary field is in bad state
	*/
	public class RollUpSummaryException extends Exception {}

	/**
	 *   Which rollup operation you want to perform
	 *   Modify this if you need to add or remove rollup operations
	 *   i.e We may add Weighted Avg in the future
	 */
	public enum OperationEnum {
		Sum,
		Max,
		Min,
		Avg,
		Count
	}
	/**
	*   Creating fields to roll
	*/
	public class RollupSummaryField {
		public Schema.Describefieldresult rollupMaster;
		public Schema.Describefieldresult rollupDetail;
		public OperationEnum rollupOperation;
		public boolean isMasterTypeNumber;
		public boolean isDetailTypeNumber;
		public boolean isMasterTypeDateOrTime;
		public boolean isDetailTypeDateOrTime;
		public boolean isMasterTypeCurrency;

		public RollupSummaryField(Schema.Describefieldresult m, Schema.Describefieldresult d, OperationEnum op) {
			this.rollupMaster = m;
			this.rollupDetail = d;
			this.rollupOperation = op;
			this.isMasterTypeNumber = isNumberField(rollupMaster.getType());
			this.isDetailTypeNumber = isNumberField(rollupDetail.getType());
			this.isMasterTypeDateOrTime = isDateOrTimeField(rollupMaster.getType());
			this.isDetailTypeDateOrTime = isDateOrTimeField(rollupDetail.getType());
			this.isMasterTypeCurrency = isCurrencyField(rollupMaster.getType());
			validateVariables();
		}
		/**
		*    Validating given variables to check their suitability
		*/
		void validateVariables() {
			if (rollupMaster == null || rollupDetail == null || rollupOperation == null) {
				throw new RollUpSummaryException('Operational fields (rollupMaster,rollupDetail,rollupOperation) are mandatory!! Please define all required fields');
			}
			if (rollupOperation != OperationEnum.Count) {
				if ( (!isMasterTypeDateOrTime && !isMasterTypeNumber) || (!isDetailTypeDateOrTime && !isDetailTypeNumber)) {
					throw new RollUpSummaryException('Sum, Max, Min and Avg operation are allowed only for Date/DateTime/Time/Numeric fields!');
				}
			}
			if (isMasterTypeDateOrTime && (OperationEnum.Sum == rollupOperation || OperationEnum.Avg == rollupOperation)) {
				throw new RollUpSummaryException('Sum/Avg operations are not valid for Date/Datetime fields!');
			}
		}
		/**
		*    Finding out if the given field type is number or not
		*/
		Boolean isNumberField (Schema.Displaytype sdt) {
			return sdt == Schema.Displaytype.Currency
			       || sdt == Schema.Displaytype.Integer
			       || sdt == Schema.Displaytype.Percent
			       || sdt == Schema.Displaytype.Double;
		}
		/**
		*    Finding out if the given field type is Date/Time/DateTime or not
		*/
		Boolean isDateOrTimeField(Schema.DisplayType sdt) {
			return sdt == Schema.Displaytype.Time
			       || sdt == Schema.Displaytype.Date
			       || sdt == Schema.Displaytype.Datetime;
		}
		/**
		*    Finding out if the given field type is currency or not
		*/
		Boolean isCurrencyField(Schema.DisplayType sdt) {
			return sdt == Schema.Displaytype.Currency;
		}
	}

	/**
	*    @Description
	*
	*    @param ctx rollUpContext the complete context required to rollup
	*    @param detailRecordsFromTrigger child/detail records which are modified/created/deleted during the Trigger
	*    @returns Array of in memory master objects. These objects are not updated back to the database
	*            because we want client or calling code to have this freedom to do some post processing and update when required.
	*/
	public static Sobject[] rollUp(rollUpContext ctx, Sobject[] TriggerDetailRecords) {
		System.debug('TriggerDetailRecords===>' + TriggerDetailRecords);
		// API name of the lookup field on detail sobject
		String lookUpFieldName = ctx.relationlookupField.getName();
		System.debug('lookUpFieldName===>' + lookUpFieldName);
		Set<Id> masterRecordIds = new Set<Id>();
		for (Sobject kid : TriggerDetailRecords) {
			masterRecordIds.add((Id)kid.get(lookUpFieldName));
		}
		system.debug('masterRecordIds ===>' + masterRecordIds);
		return rollUp(ctx, masterRecordIds);
	}

	/**
	*    Key driver method that rolls up lookup fields based on the context. This is meant to be called from non trigger contexts like
	*    scheduled/batch apex, where we want to rollup on some master record ids.
	*
	*    @param Context the complete context required to rollup
	*    @param masterRecordIds Master record IDs whose child records should be rolled up.
	*    @returns Array of in memory master objects. These objects are not updated back to the database
	*            because we want client or calling code to have this freedom to do some post processing and update when required.
	*/
	public static Sobject[] rollUp(rollUpContext ctx,  Set<Id> masterIds) {
		//
		masterIds = masterIds.clone();
		system.debug('masterIds ===>' + masterIds);
		/**
		* Key: Id of master record
		* Value: Empty sobject with ID field, this will be used for updating the masters
		*/
		Map<Id, Sobject> masterRecordsMap = new Map<Id, Sobject>();
		for (Id mId : masterIds) {
			masterRecordsMap.put(mId, ctx.masterObject.newSobject(mId));
		}
		/**
		*    @Reminder of SOQL Template tokens
		*    0 : Query Fields
		*    1 : From object
		*    2 : Optional WHERE clause filter/filters
		*    3 : Decition of Group By field
		*/
		// #0 token : SOQL projection
		String soqlProjection = ctx.relationlookupField.getName();

		Integer rsfCount = 0;
		/**
		*    key: created alias,
		*    value: rollup summary field
		*/
		Map<String, RollupSummaryField> rsfAlaisMap = new Map<String, RollupSummaryField>();
		for (RollupSummaryField rsf : ctx.rollupFieldsList) {
			// alias are created for easy fetching via AggregateResult class
			//i.e SUM(Total_Net__c) mfld0 COUNT(Id) mfld0 etc.
			String alias = 'mfld' + rsfCount++; // Calculate an alias, using field name blew the 25 character limit in some cases
			soqlProjection += ', ' + rsf.rollupOperation + '(' + rsf.rollupDetail.getName() + ') ' + alias;
			rsfAlaisMap.put(alias, rsf);

		}
		// END OF #0 token : SOQL projection
		// #1 token for SOQL_TEMPLATE
		String detailTblName = ctx.detailObject.getDescribe().getName();
		// END OF #1 token for SOQL_TEMPLATE
		// #2 Where clause
		String whereClause = '';
		if (ctx.detailWhereClause != null && ctx.detailWhereClause.trim().length() > 0) {
			whereClause = 'AND ' + ctx.detailWhereClause ;
		}
		// END OF #2 Where clause
		// #3 Group by field
		String grpByFld = ctx.relationlookupField.getName();
		// END OF #3 Group by field
		// Formating the text query template which we have built above (SELECT {0} FROM {1} WHERE {3} in :masterIds {2} GROUP BY {3})
		String soql = String.format(SOQL_STRING, new String[] {soqlProjection, detailTblName, whereClause, grpByFld});
		System.debug('SOQL string ===> ' + soql);

		// aggregated results from built query above
		//The reason of aggregation is sending bulk detail records to this block
		List<AggregateResult> results = Database.query(soql);
		System.debug('AggregateResults ===>' + results);
		for (AggregateResult res : results) {
			Id masterRecId = (Id)res.get(grpByFld);
			Sobject masterObj = masterRecordsMap.get(masterRecId);
			if (masterObj == null) {
				System.debug(Logginglevel.WARN, 'Couldnt find any master record!! ===>' + masterRecId);
				//Move to next iteration if there is no relation to master object
				//Since objects are related via lookup this is possible
				continue;
			}

			for (String alias : rsfAlaisMap.keySet()) {
				RollupSummaryField rsf = rsfAlaisMap.get(alias);
				Object aggregatedDetailVal = res.get(alias);
				System.debug(LoggingLevel.INFO, 'Created aggregarte value is ===>' + aggregatedDetailVal + ' for the master record with id ===> ' + masterRecId);
				/*******/
				//Puting rolled up fields to master object by using alias map.
				//Object mapping
				//key: field name
				//value: aggreaged field result
				/*******/
				masterObj.put(rsf.rollupMaster.getName(), aggregatedDetailVal);
			}
			// Remove master Id record as its been processed
			masterIds.remove(masterRecId);
		}
		/**
		*    Populating rollup fields with 0 where there is no child record for master records
		*/
		for (Id masterRecId : masterIds)
			for (RollupSummaryField rsf : ctx.rollupFieldsList) {
				masterRecordsMap.get(masterRecId).put(rsf.rollupMaster.getName(), rsf.isMasterTypeNumber ? 0 : null);
			}

		return masterRecordsMap.values();
	}
}
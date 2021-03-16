public inherited sharing class DataStepData {

    public String dataTemplateId { get; set; }
    public String dataTemplateName { get; set; }
    public String filterLogic { get; set; }
    public Boolean filterOverride { get; set; }
    public List<QueryEditor.CriteriaWrapper> queryFilterList { get; set; }
    public StepSource source { get; set; }
    public StepDestination destination { get; set; }


    public DataStepData() {
    }

    public DataStepData(DataDeployRequest request) {
        if (request.getSourceType() == DataDeployRequest.Source.ENVIRONMENT) {
            this.dataTemplateId = request.getDataTemplateId();
        }
        this.source = new StepSource(request);
        this.destination = new StepDestination(request);
    }


    public inherited sharing class StepSource {
        public DataDeployRequest.Source type { get; set; }
        public String id { get; set; }
        public String branchName { get; set; }

        public StepSource() {
        }

        public StepSource(DataDeployRequest request) {

            this.type = request.getSourceType();
            switch on request.getSourceType() {
                when DATASET {
                    this.id = request.getSourceDataSetId();
                }

                // remove this when backend is ready to get environment from deployment
                when ENVIRONMENT {
                    this.id = request.getSourceCredentialId();
                }

            }
        }
    }


    public inherited sharing class StepDestination {
        public DataDeployRequest.Destination type { get; set; }
        public String id { get; set; }
        public String branchName { get; set; }

        public StepDestination() {
        }

        public StepDestination(DataDeployRequest request) {

            this.type = request.getDestinationType();
            switch on request.getDestinationType() {
                when DATASET {
                    this.id = request.getDestinationDataSetId();
                }

                // remove this when backend is ready to get environment from deployment
                when ENVIRONMENT {
                    this.id = request.getDestinationCredentialId();
                }

            }
        }
    }
}
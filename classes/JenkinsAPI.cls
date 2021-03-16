/**
 * External CI Dynamic Connector for Jenkins
 * Within this class you can send different types of http requests by only using sendRequestToCI method
 * Similarly you can use parse response body for parsing JobList response, Job Status Response and Connection Validation response
 * @author Mert YALTI
 * @date 19.06.2017
 */
public with sharing class JenkinsAPI implements IExternalCIAPI {

	public enum Parse_Types { LISTING, STATUS, VALIDATE }
	/**
     * Generates and sends Http request to Jenkins endpoints
     * @see DeployAPI
     * @param endPoint url
     * @param method Http method
     * @param optionalHeaders in case of adding manual headers to the http request
     * @param isInternal if true the request will be delivered to Copado Heroku EP or to the Jenkins directly
     * @return HttpResponse
     */
	public HttpResponse sendRequestToCI(String endPoint, String method, Map<String, String> optionalHeaders, Boolean isInternal) {
		HttpRequest req = new HttpRequest();
		req.setEndpoint(endPoint);
		req.setMethod(method);
		if (method == 'POST') {
			// fix for GCP issue with POST without body: Force Content-Length: 0
			req.setHeader('Content-Length', '0');
        }
		if (isInternal) {
			DeployAPI.setAuthHeaders(req);
		} //to authenticate agains heroku servers
		if (optionalHeaders != null) {
			for (String key : optionalHeaders.keySet()) {
				req.setHeader(key, optionalHeaders.get(key));
			}
		}
		Http h = new Http();
		return h.send(req);
	}
	/**
     * Receives HttpResponse and parses it by using proper parse pattern
     * @param type [Listing, Status or Validate]
     * @param HttpResponse
     * @return Object result
     */
	public Object parseResponseBody(String type, HttpResponse res) {
		if (res != null) {
			String responseBody = res.getBody();
			if (type == Parse_Types.LISTING.name()) {
				JobClass poc = (JobClass)JSON.deserialize(responseBody, JobClass.class);
				List<ExternalCIAPIFactory.JobList> jobList = new List<ExternalCIAPIFactory.JobList>();
				for (Jobs j : poc.jobs) {
					jobList.add(new ExternalCIAPIFactory.JobList(j.name, j.url));
				}
				return jobList;
			} else if (type == Parse_Types.STATUS.name()) {
				LastBuiltStatus poc = (lastBuiltStatus)JSON.deserialize(responseBody, lastBuiltStatus.class);
				ExternalCIAPIFactory.JobStatus jobStatus = new ExternalCIAPIFactory.JobStatus(poc.ok);
				return jobStatus;
			} else if (type == Parse_Types.VALIDATE.name()) {
				String message;
				Boolean success = false;
				if (res.getStatusCode() == 200) {
					Map<String, Object> fullMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
					success = fullMap.get('error') == null;
					if (success) {
						message = (String)fullMap.get('ok');
					} else {
						message = (String)fullMap.get('error');
					}
				} else {
					success = false;
					message = res.getStatusCode() + ' - ' + res.getStatus();
				}
				return new ExternalCIAPIFactory.Validate(success,message);
			}
		}
		return null;
	}
	//Job class wrapper to collected list of jobs
	public class JobClass {
		public List<Jobs> jobs {get; set;}
	}
	//Job details wrapper
	public class Jobs {
		public String name {get; set;}
		public String url {get; set;}
	}
	//Status wrapper
	public class LastBuiltStatus {
		public String copadoJobId {get;set;}
		public String ok {get;set;}
	}
}
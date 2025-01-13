service
getAnswers: number for: aConversation config: aConfigOrNil
	"Generate <number> assistant replies in response to aConversation. Answer a collection of new SemanticMessages for each new reply. If #shouldStream is set to true, the answers will be SemanticStreamingMessages that are completed in the background."

	| chatCompletion logRawOutput stream resumeStream |
	
	"Note: multiple responses via `n` is not supported by the Anthropic API"
	number ~= 1 ifTrue: [self error: 'anthropic models do not support requesting multiple assistant replies'].
	
	chatCompletion := self
		invokeWithConfig: aConfigOrNil
		editInput: [:input :config |
			config user ifNotNil: [:user |
				input user: user].
			
			config maxTokens ifNotNil: [:maxTokens |
				input max_tokens: maxTokens].
			
			config temperature ifNotNil: [:temperature |
				input temperature: temperature].
			config nucleusSamplingMass ifNotNil: [:p |
				input top_p: p].
			
			config shouldLogProbabilities ifNotNil: [:shouldLogProbabilities |
				input logprobs: shouldLogProbabilities].
			logRawOutput := false.
			config shouldLogRawOutput ifNotNil: [:shouldLogRawOutput |
				logRawOutput := shouldLogRawOutput].
			
			stream := false.
			config shouldStream ifNotNil: [:shouldStream |
				stream := shouldStream.
				input stream: stream].
			
			input messages:
				(aConversation messages collect: [:message | message asOpenAIObject]).
			
			aConversation activeToolSpec ifNotNil: [:toolSpec |
				self addToolSpec: toolSpec toInput: input].
			
			(stream and: [self shouldStreamRequests]) ifTrue:
				["For faster feedback, send even the request asynchronously."
				^ self handleAsyncReplies: number for: aConversation config: config  logRawOutput: logRawOutput deferStreaming:
					[:resumeBlock | resumeStream := resumeBlock]]]
		handleResponse: [:response :config |
			(stream and: [response isSuccess]) ifTrue:
				[resumeStream ifNotNil: [resumeStream value: response].
				^ self handleStreamingReplies: number for: aConversation from: response config: config logRawOutput: logRawOutput]].
	
	^ self parseMessagesFrom: chatCompletion for: aConversation logRawOutput: logRawOutput
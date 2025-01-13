private - requests
parseMessageFrom: chatCompletionChoice for: aConversation logRawOutput: logRawOutput

	| messageResult message |
	messageResult := chatCompletionChoice.
	message := SemanticMessage
		conversation: aConversation
		role: messageResult role
		content: (messageResult content first type = 'text' ifTrue: [messageResult content first text] ifFalse: [messageResult content]).
	
	logRawOutput ifTrue:
		[message rawOutput:
			(JsonObject new
				chatCompletionChoice: chatCompletionChoice;
				yourself)].
	
	messageResult tool_calls ifNotNil: [:toolCalls |
		message toolCalls:
			(self parseToolCallsFrom: toolCalls toolSpec: aConversation activeToolSpec)].
	
	chatCompletionChoice logprobs ifNotNil: [:logprobs |
		message tokenProbabilities:
			(self parseTokenProbabilitiesFrom: logprobs)].
	
	^ message
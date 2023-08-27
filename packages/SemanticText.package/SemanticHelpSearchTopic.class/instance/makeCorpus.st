searching - semantic
makeCorpus

	"Other than the DocumentCache, do not preserve the corpus across search topics since every search topic might refer to a different set of topicsToSearch."
	| allTopics newCorpus |
	"Even though super is not, be robust against cyclic topic graphs here"
	allTopics := Set new.
	self topicsToSearch do: [:rootTopic |
		allTopics addAll:
			(rootTopic semanticDeepSubtopicsSkip: [:topic |
				topic title = 'All message categories'])].
	
	newCorpus := SemanticPluggableCorpus titleBlock: #title contentBlock: #contents.
	allTopics do: [:topic |
		newCorpus addAllDocuments:
			(self cachedDocumentsFor: topic ifAbsentPut:
				[newCorpus addFragmentDocumentsFrom: topic])].
	newCorpus updateEmbeddings.
	
	^ newCorpus
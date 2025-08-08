import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as cors from 'cors';
import OpenAI from 'openai';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize OpenAI (you'll need to set this in Firebase Functions config)
const openai = new OpenAI({
  apiKey: functions.config().openai?.key || process.env.OPENAI_API_KEY,
});

// Enable CORS
const corsHandler = cors({origin: true});

// MARK: - Thought Analysis Function

export const analyzeThought = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      // Verify authentication
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      // Verify the token (simplified for MVP)
      // In production, use Firebase Admin SDK to verify the token
      
      const {nodeId, content, nodeType, context} = req.body;

      if (!content) {
        res.status(400).json({error: 'Content is required'});
        return;
      }

      // Build analysis prompt
      const contextText = context
        .map((node: any) => `- ${node.content} (${node.type})`)
        .join('\n');

      const prompt = `
Analyze this thought in context:

MAIN THOUGHT: "${content}" (Type: ${nodeType})

CONTEXT:
${contextText}

Please provide:
1. A brief analysis of the thought's significance
2. Confidence level (0.0-1.0)
3. 2-3 specific suggestions for development
4. Relationship score with context (0.0-1.0)

Respond in JSON format.
`;

      // Call OpenAI
      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are a cognitive analysis AI. Provide structured, insightful analysis of thoughts and ideas."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 500,
        temperature: 0.3
      });

      const aiResponse = completion.choices[0]?.message?.content;
      
      if (!aiResponse) {
        throw new Error('No response from AI');
      }

      // Parse AI response or create structured response
      let analysisResult;
      try {
        analysisResult = JSON.parse(aiResponse);
      } catch {
        // Fallback if AI doesn't return proper JSON
        analysisResult = {
          nodeId,
          analysis: aiResponse,
          confidence: 0.7,
          suggestions: ["Explore deeper connections", "Consider alternative perspectives"],
          relationshipScore: 0.6
        };
      }

      // Ensure required fields
      const result = {
        nodeId,
        analysis: analysisResult.analysis || aiResponse,
        confidence: analysisResult.confidence || 0.7,
        suggestions: analysisResult.suggestions || ["Develop further", "Connect with related ideas"],
        relationshipScore: analysisResult.relationshipScore || 0.5
      };

      res.json(result);

    } catch (error) {
      console.error('Error in analyzeThought:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Association Generation Function

export const generateAssociations = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {targetNode, contextNodes} = req.body;

      if (!targetNode?.content) {
        res.status(400).json({error: 'Target node content is required'});
        return;
      }

      const contextText = contextNodes
        .map((node: any, index: number) => `${index}: "${node.content}" (${node.type})`)
        .join('\n');

      const prompt = `
Find semantic associations for this target thought:

TARGET: "${targetNode.content}" (${targetNode.type})

CONTEXT NODES:
${contextText}

Identify the most relevant associations and return as JSON:
{
  "associations": [
    {
      "targetNodeId": "target_id",
      "relatedNodeId": "context_node_id", 
      "associationType": "semantic|thematic|causal|temporal",
      "strength": 0.8,
      "explanation": "why they're related",
      "confidence": 0.9
    }
  ]
}

Return only valid associations with strength > 0.3.
`;

      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are an expert at finding semantic and conceptual associations between ideas. Return only valid JSON."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 800,
        temperature: 0.2
      });

      const aiResponse = completion.choices[0]?.message?.content;
      
      let associations;
      try {
        const parsed = JSON.parse(aiResponse || '{}');
        associations = parsed.associations || [];
        
        // Map context node indices to actual IDs
        associations = associations.map((assoc: any) => ({
          ...assoc,
          targetNodeId: targetNode.id,
          relatedNodeId: contextNodes[parseInt(assoc.relatedNodeId)] ? 
            contextNodes[parseInt(assoc.relatedNodeId)].id : assoc.relatedNodeId
        }));
        
      } catch {
        // Fallback associations
        associations = contextNodes.slice(0, 2).map((node: any) => ({
          targetNodeId: targetNode.id,
          relatedNodeId: node.id,
          associationType: "semantic",
          strength: 0.5,
          explanation: "Potentially related concepts",
          confidence: 0.4
        }));
      }

      res.json({associations});

    } catch (error) {
      console.error('Error in generateAssociations:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Insight Generation Function

export const generateInsight = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {nodes} = req.body;

      if (!nodes || nodes.length === 0) {
        res.status(400).json({error: 'Nodes array is required'});
        return;
      }

      const thoughtsText = nodes
        .map((node: any, index: number) => `${index + 1}. "${node.content}" (${node.type})`)
        .join('\n');

      const prompt = `
Generate a meta-cognitive insight from these interconnected thoughts:

THOUGHTS:
${thoughtsText}

Provide a higher-level insight that synthesizes these thoughts. Look for:
- Emerging patterns or themes
- Contradictions that reveal deeper truths  
- Novel connections between concepts
- Meta-patterns about thinking itself

Return as JSON:
{
  "insight": "Your synthesized insight here",
  "theme": "The central theme or pattern",
  "confidence": 0.8,
  "supportingNodeIds": ["id1", "id2"]
}

Be profound yet concise. Focus on what emerges from the combination that isn't obvious from individual thoughts.
`;

      const completion = await openai.chat.completions.create({
        model: "gpt-4",  // Use GPT-4 for more sophisticated insights
        messages: [
          {
            role: "system",
            content: "You are a master of meta-cognition and pattern synthesis. Generate deep, thought-provoking insights that reveal hidden connections and emergent meaning."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 600,
        temperature: 0.4
      });

      const aiResponse = completion.choices[0]?.message?.content;
      
      let insight;
      try {
        insight = JSON.parse(aiResponse || '{}');
        
        // Ensure supporting node IDs are mapped correctly
        if (insight.supportingNodeIds && Array.isArray(insight.supportingNodeIds)) {
          insight.supportingNodeIds = insight.supportingNodeIds
            .map((id: any) => {
              const index = parseInt(id) - 1;
              return nodes[index]?.id || id;
            })
            .filter(Boolean);
        }
        
      } catch {
        // Fallback insight
        insight = {
          insight: aiResponse || "These thoughts reveal interesting patterns about interconnected thinking.",
          theme: "Cognitive Pattern Analysis",
          confidence: 0.6,
          supportingNodeIds: nodes.slice(0, 2).map((n: any) => n.id)
        };
      }

      res.json(insight);

    } catch (error) {
      console.error('Error in generateInsight:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Embedding Generation Function

export const generateEmbedding = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {text} = req.body;

      if (!text) {
        res.status(400).json({error: 'Text is required'});
        return;
      }

      // Generate embedding using OpenAI's text-embedding model
      const response = await openai.embeddings.create({
        model: "text-embedding-ada-002",
        input: text,
      });

      const embedding = response.data[0]?.embedding;

      if (!embedding) {
        throw new Error('Failed to generate embedding');
      }

      res.json({
        embedding: embedding,
        dimensions: embedding.length
      });

    } catch (error) {
      console.error('Error in generateEmbedding:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Emotional Analysis Function

export const analyzeEmotionalState = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {nodes} = req.body;

      if (!nodes || nodes.length === 0) {
        res.status(400).json({error: 'Nodes array is required'});
        return;
      }

      const thoughtsText = nodes
        .map((node: any) => `"${node.content}"`)
        .join('\n');

      const prompt = `
Analyze the emotional undertones of these thoughts:

THOUGHTS:
${thoughtsText}

Provide emotional analysis as JSON:
{
  "overallValence": 0.2,
  "arousal": 0.6,
  "dominantEmotion": "contemplative",
  "emotionalTrajectory": [
    {
      "nodeId": "id1",
      "valence": 0.1,
      "arousal": 0.5,
      "emotion": "reflective"
    }
  ],
  "confidence": 0.8
}

Valence: -1.0 (negative) to 1.0 (positive)
Arousal: 0.0 (calm) to 1.0 (excited)
Use nuanced emotion labels like: contemplative, curious, determined, conflicted, inspired, etc.
`;

      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are an expert in emotional analysis and affective computing. Provide precise emotional assessments."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 800,
        temperature: 0.3
      });

      const aiResponse = completion.choices[0]?.message?.content;
      
      let emotionalAnalysis;
      try {
        emotionalAnalysis = JSON.parse(aiResponse || '{}');
        
        // Map node IDs correctly
        if (emotionalAnalysis.emotionalTrajectory) {
          emotionalAnalysis.emotionalTrajectory = emotionalAnalysis.emotionalTrajectory.map((point: any, index: number) => ({
            ...point,
            nodeId: nodes[index]?.id || point.nodeId
          }));
        }
        
      } catch {
        // Fallback emotional analysis
        emotionalAnalysis = {
          overallValence: 0.0,
          arousal: 0.5,
          dominantEmotion: "neutral",
          emotionalTrajectory: nodes.map((node: any) => ({
            nodeId: node.id,
            valence: 0.0,
            arousal: 0.5,
            emotion: "neutral"
          })),
          confidence: 0.5
        };
      }

      res.json(emotionalAnalysis);

    } catch (error) {
      console.error('Error in analyzeEmotionalState:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Batch Analysis Function

export const batchAnalyze = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {nodes} = req.body;

      if (!nodes || nodes.length === 0) {
        res.status(400).json({error: 'Nodes array is required'});
        return;
      }

      // Process each node with minimal context for efficiency
      const results = await Promise.all(
        nodes.map(async (node: any) => {
          try {
            const prompt = `
Quickly analyze this thought:
"${node.content}" (Type: ${node.type})

Provide brief JSON analysis:
{
  "analysis": "Brief insight",
  "confidence": 0.7,
  "suggestions": ["suggestion1", "suggestion2"],
  "relationshipScore": 0.5
}
`;

            const completion = await openai.chat.completions.create({
              model: "gpt-3.5-turbo",
              messages: [
                {
                  role: "system",
                  content: "Provide quick, structured analysis of individual thoughts."
                },
                {
                  role: "user",
                  content: prompt
                }
              ],
              max_tokens: 200,
              temperature: 0.2
            });

            const aiResponse = completion.choices[0]?.message?.content;
            
            let analysis;
            try {
              analysis = JSON.parse(aiResponse || '{}');
            } catch {
              analysis = {
                analysis: "Interesting thought worth exploring further",
                confidence: 0.5,
                suggestions: ["Develop further", "Connect with others"],
                relationshipScore: 0.4
              };
            }

            return {
              nodeId: node.id,
              ...analysis
            };

          } catch (error) {
            console.error(`Error analyzing node ${node.id}:`, error);
            return {
              nodeId: node.id,
              analysis: "Analysis unavailable",
              confidence: 0.0,
              suggestions: [],
              relationshipScore: 0.0
            };
          }
        })
      );

      res.json({results});

    } catch (error) {
      console.error('Error in batchAnalyze:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

// MARK: - Stream Chat Function (Placeholder)

export const streamChat = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        res.status(401).json({error: 'Authentication required'});
        return;
      }

      const {prompt} = req.body;

      if (!prompt) {
        res.status(400).json({error: 'Prompt is required'});
        return;
      }

      // For MVP, return a simple response
      // In production, implement Server-Sent Events or WebSocket streaming
      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: "You are a thoughtful AI companion helping with cognitive exploration."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 300,
        temperature: 0.6
      });

      const response = completion.choices[0]?.message?.content || "I'm here to help you explore your thoughts.";

      res.json({
        content: response,
        conversationId: `conv_${Date.now()}`
      });

    } catch (error) {
      console.error('Error in streamChat:', error);
      res.status(500).json({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  });
});

You are assisting with two interconnected objectives within an organization's project management evolution: integrating Azure DevOps and JIRA backlogs, and establishing effective sprint management practices for a new team using Azure DevOps.

Project Context:
The organization uses a dual-tooling approach where:
- Development teams work primarily in Azure DevOps, using the CRM Agile Process template
- Management and Product Owners work in JIRA
- Features are directly linked to Stories/Tasks/Bugs in Azure DevOps
- A one-to-one mapping exists between JIRA Epics and Azure DevOps Features

Current Technical Setup in Azure DevOps:
- Features are enabled in backlog navigation levels
- The system uses a flat hierarchy with direct links from Features to work items
- Tasks represent the lowest level in the work item hierarchy
- The project follows the CRM Agile Process template
- Viewing settings and permissions influence work item display and management

Sprint Planning Considerations:
- Hierarchical filtering conflicts with forecasting features
- Focused queries serve as an alternative to hierarchical filters for sprint planning
- True user stories should follow the format "As a [user], I want [goal] so that [value]"
- Technical tasks and infrastructure updates require special consideration
- Tasks cannot be nested under other tasks, necessitating alternative organization approaches

Work Item Organization Principles:
- User stories must represent actual user value
- Task relationships are managed through "Related Work" links
- Consistent naming conventions are essential
- "Parent tasks" should be reframed as appropriately structured user stories

Integration Goals:
- Maintain simple, one-directional synchronization between systems
- Allow Product Owners to track progress without leaving JIRA
- Enable development teams to work effectively in Azure DevOps
- Preserve existing work item relationships and hierarchies

Sprint Management Learning Goals:
- Understand effective sprint planning techniques within Azure DevOps constraints
- Balance forecasting capabilities with work item organization needs
- Develop practical approaches for organizing technical work and user stories
- Establish clear processes for managing work item relationships
- Create efficient sprint planning views and queries

When responding to questions:
1. Consider both technical feasibility and organizational impact
2. Address how changes affect both development teams and management
3. Maintain awareness of the distinct needs of different user groups
4. Keep solutions aligned with the simplified integration approach
5. Consider implications for work item tracking and relationship management
6. Provide context about how suggestions impact existing processes
7. Explain sprint management concepts progressively, building from fundamentals
8. Offer practical examples that illustrate both correct approaches and common pitfalls

Remember that the organization is prioritizing:
- Simplicity and effectiveness over comprehensive integration
- Enabling each team to work efficiently in their chosen tool
- Building strong sprint management practices for the new team
- Maintaining clear work item organization principles
- Supporting effective sprint planning and forecasting capabilities

When discussing sprint management, focus on practical approaches that work within Azure DevOps constraints while maintaining good agile practices. When addressing integration, emphasize solutions that preserve the team's ability to plan and execute sprints effectively.


_________________________
## Mermaid
```mermaid

graph TB
    %% Define line colors using linkStyle
    linkStyle default stroke:#2563eb,stroke-width:2
    
    subgraph JIRA System
        %% Top Level - Epic
        JE[Epic]
        
        %% Second Level - Stories, Tasks, Bugs
        subgraph JIRA Work Items
            JS[Story]
            JB[Bug]
            JT[Task with Flag]
        end
        
        %% Third Level - Subtasks
        subgraph JIRA Subtasks
            JST1[JIRA Subtask 1]
            JST2[JIRA Subtask 2]
            JBT[Bug Subtask]
        end
        
        %% JIRA Hierarchy - numbered for linkStyle
        JE --> |1| JS 
        JE --> |2| JB
        JE --> |3| JT
        JS --> |4| JST1
        JS --> |5| JST2
        JB --> |6| JBT
        
        %% Cross-item relationships - numbered for linkStyle
        JB -.->|Related to| JS
        JT -.->|Blocks| JS
        JT -.->|Blocks| JB
    end
    
    subgraph Azure DevOps System
        %% Top Level - Feature
        AF[Feature]
        
        %% Second Level - Stories, Issues, Bugs
        subgraph Azure Work Items
            AS[Story]
            AB[Bug]
            AI[Issue]
        end
        
        %% Third Level - Tasks
        subgraph Azure Tasks
            AT1[Azure Task 1]
            AT2[Azure Task 2]
            ABT[Bug Task]
        end
        
        %% Azure Hierarchy - numbered for linkStyle
        AF --> |7| AS
        AF --> |8| AB
        AF --> |9| AI
        AS --> |10| AT1
        AS --> |11| AT2
        AB --> |12| ABT
        
        %% Cross-item relationships - numbered for linkStyle
        AB -.->|Related to| AS
        AI -.->|Blocks| AS
        AI -.->|Blocks| AB
    end
    
    %% Cross-System Synchronization - numbered for linkStyle
    JE ===|1:1 Sync| AF
    JS ===|1:1 Sync| AS
    JB ===|1:1 Sync| AB
    JT ===|"Sync if Flagged"| AI
    
    %% Styling nodes
    style JE fill:#0052CC,color:#fff
    style JS fill:#0052CC,color:#fff
    style JST1 fill:#00C7E6,color:#000
    style JST2 fill:#00C7E6,color:#000
    style JB fill:#FF5630,color:#fff
    style JBT fill:#FF8F73,color:#000
    style JT fill:#FFF4E5,color:#000,stroke:#FF9900,stroke-width:3px
    
    style AF fill:#007ACC,color:#fff
    style AS fill:#007ACC,color:#fff
    style AT1 fill:#4CAF50,color:#fff
    style AT2 fill:#4CAF50,color:#fff
    style AB fill:#E74C3C,color:#fff
    style ABT fill:#FF7675,color:#fff
    style AI fill:#F6C342,color:#000

    %% Line Legend
    subgraph Legend
        L1[Hierarchical Relationship]
        L2[Cross-item Relationship]
        L3[System Synchronization]
        
        %% Example lines for legend
        L4[ ] --> L1
        L5[ ] -.-> L2
        L6[ ] === L3
        
        %% Hide legend boxes
        style L4 fill:none,stroke:none
        style L5 fill:none,stroke:none
        style L6 fill:none,stroke:none
    end

    %% Notes Section
    subgraph Key Information
        note1[Tasks flagged as blockers sync to Azure DevOps Issues]
        note2[One-to-one sync maintains hierarchy integrity]
        note3[Subtasks remain in their respective systems]
    end

    subgraph Number References
        NR["1: Epic → Story
        2: Epic → Bug
        3: Epic → Task
        4: Story → Subtask 1
        5: Story → Subtask 2
        6: Bug → Bug Subtask
        7: Feature → Story
        8: Feature → Bug
        9: Feature → Issue
        10: Story → Task 1
        11: Story → Task 2
        12: Bug → Bug Task"]
    end

    %% Styling classes
    classDef note fill:#f9f,stroke:#333,stroke-dasharray: 5 5
    classDef ref fill:#f3f4f6,stroke:#d1d5db

    %% Apply styles
    class note1,note2,note3 note
    class NR ref

    %% Line Styling
    linkStyle 0,1,2,3,4,5,6,7,8,9,10,11 stroke:#2563eb,stroke-width:2 %% Blue for hierarchy
    linkStyle 12,13,14,15,16,17 stroke:#dc2626,stroke-width:2,stroke-dasharray: 5 5 %% Red dashed for cross-item relationships
    linkStyle 18,19,20,21 stroke:#059669,stroke-width:3 %% Green thick for synchronization
    %% Legend line styles
    linkStyle 22 stroke:#2563eb,stroke-width:2
    linkStyle 23 stroke:#dc2626,stroke-width:2,stroke-dasharray: 5 5
    linkStyle 24 stroke:#059669,stroke-width:3

```
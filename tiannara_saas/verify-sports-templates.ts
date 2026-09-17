/**
 * Verify Sports Prediction Templates Integration
 * 
 * Tests that the 3 new sports templates are properly added to the workflow catalog.
 */

import { 
  WORKFLOW_TEMPLATES, 
  getTemplateById, 
  getTemplatesByCategory,
  canAccessTemplate,
  WorkflowTemplate
} from './lib/workflow-templates'

console.log('='.repeat(80))
console.log('  SPORTS PREDICTION TEMPLATES VERIFICATION')
console.log('='.repeat(80))

// Test 1: Check total template count
console.log('\n✅ TEST 1: Template Count')
console.log(`Total templates: ${WORKFLOW_TEMPLATES.length}`)
console.log(`Expected: 15 (12 existing + 3 sports)`)
if (WORKFLOW_TEMPLATES.length === 15) {
  console.log('✅ PASSED: Correct number of templates')
} else {
  console.log('❌ FAILED: Expected 15 templates')
  process.exit(1)
}

// Test 2: Verify sports templates exist
console.log('\n✅ TEST 2: Sports Templates Exist')
const sportsTemplateIds = [
  'match_winner_prediction',
  'jackpot_optimizer',
  'live_bet_edge'
]

let allFound = true
for (const id of sportsTemplateIds) {
  const template = getTemplateById(id)
  if (template) {
    console.log(`  ✅ ${id}: Found`)
  } else {
    console.log(`  ❌ ${id}: NOT FOUND`)
    allFound = false
  }
}

if (!allFound) {
  console.log('❌ FAILED: Some templates missing')
  process.exit(1)
}
console.log('✅ PASSED: All sports templates found')

// Test 3: Verify template properties
console.log('\n✅ TEST 3: Template Properties')
const matchWinner = getTemplateById('match_winner_prediction')
if (matchWinner) {
  console.log(`Name: ${matchWinner.name}`)
  console.log(`Category: ${matchWinner.category}`)
  console.log(`Difficulty: ${matchWinner.difficulty}`)
  console.log(`Tier Required: ${matchWinner.tierRequired}`)
  console.log(`Nodes: ${matchWinner.nodes.length}`)
  console.log(`Edges: ${matchWinner.edges.length}`)
  console.log(`Tags: ${matchWinner.tags.join(', ')}`)
  
  const hasRequiredProps = 
    matchWinner.category === 'prediction' &&
    matchWinner.difficulty === 'beginner' &&
    matchWinner.tierRequired === 'professional' &&
    matchWinner.nodes.length === 5 &&
    matchWinner.edges.length === 4
  
  if (hasRequiredProps) {
    console.log('✅ PASSED: Match Winner template properties correct')
  } else {
    console.log('❌ FAILED: Properties incorrect')
    process.exit(1)
  }
}

// Test 4: Verify category filtering
console.log('\n✅ TEST 4: Category Filtering')
const predictionTemplates = getTemplatesByCategory('prediction')
console.log(`Prediction templates: ${predictionTemplates.length}`)
console.log(`Expected: At least 3 (our new sports templates)`)

if (predictionTemplates.length >= 3) {
  console.log('✅ PASSED: Category filtering works')
} else {
  console.log('❌ FAILED: Not enough prediction templates')
  process.exit(1)
}

// Test 5: Verify tier access control
console.log('\n✅ TEST 5: Tier Access Control')
const jackpotTemplate = getTemplateById('jackpot_optimizer')
const liveBetTemplate = getTemplateById('live_bet_edge')

if (jackpotTemplate && liveBetTemplate) {
  // Professional user should access jackpot but not live bet
  const proCanAccessJackpot = canAccessTemplate(jackpotTemplate, 'professional')
  const proCanAccessLiveBet = canAccessTemplate(liveBetTemplate, 'professional')
  
  console.log(`Professional can access Jackpot: ${proCanAccessJackpot} (expected: true)`)
  console.log(`Professional can access Live Bet: ${proCanAccessLiveBet} (expected: false)`)
  
  // Enterprise user should access both
  const enterpriseCanAccessJackpot = canAccessTemplate(jackpotTemplate, 'enterprise')
  const enterpriseCanAccessLiveBet = canAccessTemplate(liveBetTemplate, 'enterprise')
  
  console.log(`Enterprise can access Jackpot: ${enterpriseCanAccessJackpot} (expected: true)`)
  console.log(`Enterprise can access Live Bet: ${enterpriseCanAccessLiveBet} (expected: true)`)
  
  if (proCanAccessJackpot && !proCanAccessLiveBet && 
      enterpriseCanAccessJackpot && enterpriseCanAccessLiveBet) {
    console.log('✅ PASSED: Tier access control working correctly')
  } else {
    console.log('❌ FAILED: Tier access control incorrect')
    process.exit(1)
  }
}

// Test 6: Verify workflow structure
console.log('\n✅ TEST 6: Workflow Structure')
const liveBet = getTemplateById('live_bet_edge')
if (liveBet) {
  console.log(`Nodes in Live Betting Edge:`)
  liveBet.nodes.forEach((node: any, idx: number) => {
    console.log(`  ${idx + 1}. ${node.data.label} (${node.type})`)
  })
  
  console.log(`\nEdges: ${liveBet.edges.length}`)
  liveBet.edges.forEach((edge: any, idx: number) => {
    console.log(`  ${idx + 1}. ${edge.source} → ${edge.target}`)
  })
  
  const hasCorrectStructure = 
    liveBet.nodes.length === 5 &&
    liveBet.edges.length === 4 &&
    liveBet.nodes[0].type === 'input' &&
    liveBet.nodes[4].type === 'action'
  
  if (hasCorrectStructure) {
    console.log('\n✅ PASSED: Workflow structure correct')
  } else {
    console.log('\n❌ FAILED: Workflow structure incorrect')
    process.exit(1)
  }
}

// Test 7: Verify dashboard widgets
console.log('\n✅ TEST 7: Dashboard Widgets')
if (matchWinner && matchWinner.dashboardWidgets) {
  console.log(`Match Winner Widgets: ${matchWinner.dashboardWidgets.length}`)
  matchWinner.dashboardWidgets.forEach((widget: string) => {
    console.log(`  • ${widget}`)
  })
  
  if (matchWinner.dashboardWidgets.length >= 3) {
    console.log('✅ PASSED: Dashboard widgets defined')
  } else {
    console.log('❌ FAILED: Not enough widgets')
    process.exit(1)
  }
}

// Test 8: Verify automation rules (Live Betting)
console.log('\n✅ TEST 8: Automation Rules')
if (liveBet && liveBet.automationRules) {
  console.log(`Live Betting Automation Rules: ${liveBet.automationRules.length}`)
  liveBet.automationRules.forEach((rule: string) => {
    console.log(`  • ${rule}`)
  })
  
  if (liveBet.automationRules.length >= 2) {
    console.log('✅ PASSED: Automation rules defined')
  } else {
    console.log('❌ FAILED: Not enough automation rules')
    process.exit(1)
  }
}

// Summary
console.log('\n' + '='.repeat(80))
console.log('  ALL TESTS PASSED ✅')
console.log('='.repeat(80))
console.log('\nSports Prediction Templates Successfully Integrated:')
console.log('  ✅ Match Winner Prediction (Beginner - Professional)')
console.log('  ✅ Jackpot Match Optimizer (Intermediate - Professional)')
console.log('  ✅ Live Betting Edge Detector (Advanced - Enterprise)')
console.log('\nNext Steps:')
console.log('  1. Build UI components in tiannara_saas/components/sports/')
console.log('  2. Update workflow executor for sports_prediction task')
console.log('  3. Create demo data generator')
console.log('  4. Test end-to-end workflow execution')
console.log()

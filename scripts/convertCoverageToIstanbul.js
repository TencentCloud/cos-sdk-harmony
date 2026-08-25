#!/usr/bin/env node
/**
 * 鸿蒙覆盖率格式转换工具
 * 将鸿蒙单测覆盖率文件 (coverageReport.json) 转换为 Jest/Istanbul 格式
 * 
 * 用法: node convertCoverageToIstanbul.js <inputFile> [outputFile]
 * 示例: node convertCoverageToIstanbul.js ./coverageReport.json ./coverage-final.json
 */

const fs = require('fs');
const path = require('path');

/**
 * 将鸿蒙覆盖率格式转换为 Istanbul 格式
 * @param {Object} harmonyData 鸿蒙格式的覆盖率数据
 * @returns {Object} Istanbul 格式的覆盖率数据
 */
function convertToIstanbul(harmonyData) {
  const istanbulCoverage = {};

  if (!harmonyData.files || !Array.isArray(harmonyData.files)) {
    console.error('错误: 输入文件格式不正确，缺少 files 数组');
    return istanbulCoverage;
  }

  for (const file of harmonyData.files) {
    const filePath = file.path;
    const fileCoverage = {
      path: filePath,
      // 汇总信息
      lines: {
        total: file.summary?.lines?.total || 0,
        covered: file.summary?.lines?.covered || 0,
        skipped: 0,
        pct: file.summary?.lines?.pct || 0
      },
      functions: {
        total: file.summary?.functions?.total || 0,
        covered: file.summary?.functions?.covered || 0,
        skipped: 0,
        pct: file.summary?.functions?.pct || 0
      },
      statements: {
        total: file.summary?.lines?.total || 0,
        covered: file.summary?.lines?.covered || 0,
        skipped: 0,
        pct: file.summary?.lines?.pct || 0
      },
      branches: {
        total: file.summary?.branches?.total || 0,
        covered: file.summary?.branches?.covered || 0,
        skipped: 0,
        pct: file.summary?.branches?.pct || 0
      },
      // 位置映射
      statementMap: {},
      fnMap: {},
      branchMap: {},
      // 执行次数
      s: {},
      f: {},
      b: {}
    };

    // 处理语句映射 (statementMap) 和执行次数 (s)
    // 使用 exeLine 和 executedLineCount 来构建
    const executedLineCount = file.summary?.lines?.executedLineCount || [];
    const exeLine = file.exeLine || {};
    
    let statementIndex = 0;
    // exeLine 的 key 是索引，value 是实际行号
    const lineNumbers = Object.values(exeLine).sort((a, b) => a - b);
    
    for (const lineNum of lineNumbers) {
      const lineIdx = lineNum - 1; // 数组索引从0开始
      const count = executedLineCount[lineIdx];
      
      if (count !== undefined && count !== -1) {
        fileCoverage.statementMap[statementIndex] = {
          start: { line: lineNum, column: 0 },
          end: { line: lineNum, column: null }
        };
        fileCoverage.s[statementIndex] = count;
        statementIndex++;
      }
    }

    // 处理函数映射 (fnMap) 和执行次数 (f)
    // 使用全局递增的分支索引，确保 branchMap 和 b 的 key 是纯数字
    let branchIndex = 0;
    
    if (file.functions && Array.isArray(file.functions)) {
      for (let i = 0; i < file.functions.length; i++) {
        const func = file.functions[i];
        const funcName = func.name || `(anonymous_${i})`;
        
        // 获取函数的位置信息
        let startLoc = { line: 1, column: 0 };
        let endLoc = { line: 1, column: null };
        
        if (func.regions && func.regions.length > 0) {
          const firstRegion = func.regions[0];
          startLoc = {
            line: firstRegion.startLoc?.line || 1,
            column: firstRegion.startLoc?.col || 0
          };
          endLoc = {
            line: firstRegion.endLoc?.line || 1,
            column: firstRegion.endLoc?.col || null
          };
        }

        fileCoverage.fnMap[i] = {
          name: funcName,
          decl: {
            start: { ...startLoc },
            end: { line: startLoc.line, column: null }
          },
          loc: {
            start: startLoc,
            end: endLoc
          }
        };

        fileCoverage.f[i] = func.count || 0;

        // 处理分支映射 (branchMap) 和执行次数 (b)
        // 使用全局递增的纯数字作为 key，CI/CD 工具要求 key 必须是纯数字
        if (func.branches && Array.isArray(func.branches)) {
          for (let j = 0; j < func.branches.length; j++) {
            const branch = func.branches[j];
            
            fileCoverage.branchMap[branchIndex] = {
              type: 'if',
              loc: {
                start: {
                  line: branch.startLoc?.line || 1,
                  column: branch.startLoc?.col || 0
                },
                end: {
                  line: branch.endLoc?.line || 1,
                  column: branch.endLoc?.col || null
                }
              },
              locations: [
                {
                  start: {
                    line: branch.startLoc?.line || 1,
                    column: branch.startLoc?.col || 0
                  },
                  end: {
                    line: branch.endLoc?.line || 1,
                    column: branch.endLoc?.col || null
                  }
                }
              ]
            };

            // b 的值是数组，表示每个分支路径的执行次数
            fileCoverage.b[branchIndex] = [
              branch.trueCount || 0,
              branch.falseCount || 0
            ];
            
            branchIndex++;
          }
        }
      }
    }

    // 更新汇总信息（基于实际解析的数据）
    const stmtTotal = Object.keys(fileCoverage.s).length;
    const stmtCovered = Object.values(fileCoverage.s).filter(v => v > 0).length;
    fileCoverage.statements.total = stmtTotal;
    fileCoverage.statements.covered = stmtCovered;
    fileCoverage.statements.pct = stmtTotal > 0 ? Math.round((stmtCovered / stmtTotal) * 1000) / 10 : 100;

    const fnTotal = Object.keys(fileCoverage.f).length;
    const fnCovered = Object.values(fileCoverage.f).filter(v => v > 0).length;
    fileCoverage.functions.total = fnTotal;
    fileCoverage.functions.covered = fnCovered;
    fileCoverage.functions.pct = fnTotal > 0 ? Math.round((fnCovered / fnTotal) * 1000) / 10 : 100;

    const branchTotal = Object.keys(fileCoverage.b).length * 2; // 每个分支有 true/false 两个路径
    const branchCovered = Object.values(fileCoverage.b).flat().filter(v => v > 0).length;
    fileCoverage.branches.total = branchTotal;
    fileCoverage.branches.covered = branchCovered;
    fileCoverage.branches.pct = branchTotal > 0 ? Math.round((branchCovered / branchTotal) * 1000) / 10 : 100;

    istanbulCoverage[filePath] = fileCoverage;
  }

  return istanbulCoverage;
}

/**
 * 主函数
 */
function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.log('用法: node convertCoverageToIstanbul.js <inputFile> [outputFile]');
    console.log('示例: node convertCoverageToIstanbul.js ./coverageReport.json ./coverage-final.json');
    process.exit(1);
  }

  const inputFile = args[0];
  const outputFile = args[1] || 'coverage-final.json';

  // 检查输入文件是否存在
  if (!fs.existsSync(inputFile)) {
    console.error(`错误: 输入文件不存在: ${inputFile}`);
    process.exit(1);
  }

  console.log(`正在读取鸿蒙覆盖率文件: ${inputFile}`);
  
  try {
    const rawData = fs.readFileSync(inputFile, 'utf-8');
    const harmonyData = JSON.parse(rawData);

    console.log('正在转换为 Istanbul 格式...');
    const istanbulData = convertToIstanbul(harmonyData);

    const fileCount = Object.keys(istanbulData).length;
    console.log(`已转换 ${fileCount} 个文件的覆盖率数据`);

    // 写入输出文件
    fs.writeFileSync(outputFile, JSON.stringify(istanbulData, null, 2), 'utf-8');
    console.log(`转换完成! 输出文件: ${outputFile}`);

    // 输出汇总信息
    if (harmonyData.summary) {
      console.log('\n覆盖率汇总:');
      console.log(`  行覆盖率: ${harmonyData.summary.lines?.pct || 0}% (${harmonyData.summary.lines?.covered || 0}/${harmonyData.summary.lines?.total || 0})`);
      console.log(`  函数覆盖率: ${harmonyData.summary.functions?.pct || 0}% (${harmonyData.summary.functions?.covered || 0}/${harmonyData.summary.functions?.total || 0})`);
      console.log(`  分支覆盖率: ${harmonyData.summary.branches?.pct || 0}% (${harmonyData.summary.branches?.covered || 0}/${harmonyData.summary.branches?.total || 0})`);
    }

  } catch (error) {
    console.error(`错误: 处理文件时出错: ${error.message}`);
    process.exit(1);
  }
}

main();
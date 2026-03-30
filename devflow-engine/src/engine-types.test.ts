import { describe, expect, it } from 'bun:test'
import { toScore, toFilePath, toBonus } from './types.js'

describe('toScore', () => {
  it('accepts valid range', () => {
    expect(toScore(0)).toBe(0)
    expect(toScore(50)).toBe(50)
    expect(toScore(100)).toBe(100)
  })

  it('throws below 0', () => {
    expect(() => toScore(-1)).toThrow(RangeError)
  })

  it('throws above 100', () => {
    expect(() => toScore(101)).toThrow(RangeError)
  })
})

describe('toFilePath', () => {
  it('accepts valid path', () => {
    expect(toFilePath('src/foo.ts')).toBe('src/foo.ts')
  })

  it('throws on empty string', () => {
    expect(() => toFilePath('')).toThrow()
  })

  it('throws on whitespace-only string', () => {
    expect(() => toFilePath('   ')).toThrow()
  })
})

describe('toBonus', () => {
  it('clamps above +10', () => {
    expect(toBonus(15)).toBe(10)
  })

  it('clamps below -10', () => {
    expect(toBonus(-20)).toBe(-10)
  })

  it('passes through valid values', () => {
    expect(toBonus(10)).toBe(10)
    expect(toBonus(-10)).toBe(-10)
    expect(toBonus(0)).toBe(0)
  })
})

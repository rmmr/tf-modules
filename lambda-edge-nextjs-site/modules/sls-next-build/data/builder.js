const path = require("path")
const { Builder } = require("@sls-next/lambda-at-edge")

const rootDir = process.cwd()

const useServerlessTraceTarget = process.env.USE_SERVERLESS_TRACE_TARGETS === '1' ? true : false
const minifyHandlers = process.env.MINIFY_HANDLERS === '1' ? true : false

const builder = new Builder(
  rootDir,
  path.join(rootDir, ".serverless_next"),
  {
    cmd: './node_modules/.bin/next',
    cwd: rootDir,
    env: {},
    args: ['build'],
    useServerlessTraceTarget,
    minifyHandlers,
  }
);

async function main() {
  await builder.build()
}

main()
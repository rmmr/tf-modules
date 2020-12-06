const path = require("path")
const { Builder } = require("@sls-next/lambda-at-edge")

const rootDir = process.cwd()

const minifyHandlers = process.env.MINIFY_HANDLERS === '1' ? true : false
const useServerlessTraceTarget = process.env.USE_SERVERLESS_TRACE_TARGETS === '1' ? true : false
const domainRedirects = process.env.DOMAIN_REDIRECTS !== undefined ? JSON.parse(process.env.DOMAIN_REDIRECTS) : {}


async function main() {
  console.log(`Building sls next at location "${rootDir}"`)
  const builder = new Builder(
    rootDir,
    path.join(rootDir, ".serverless_next"),
    {
      cmd: './node_modules/.bin/next',
      cwd: rootDir,
      env: {},
      args: ['build'],
      minifyHandlers,
      useServerlessTraceTarget,
      domainRedirects,
    }
  );

  await builder.build()
}

main().catch(() => {
  process.exit(1)
})
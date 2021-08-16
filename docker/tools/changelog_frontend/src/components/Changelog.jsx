import React, { useState, useEffect } from "react";
import { Button, Spinner, Col, Row, Input } from "reactstrap";
import ComponentFilters from "./ComponentFilters";

// Here be dragons
// this needs split out into separate components, need to handle state of filters better too
// it's all very primitive currently.

const gerritURLs = [
  "http://review.couchbase.org",
  "https://asterix-gerrit.ics.uci.edu",
];

const jiraPrefixes = [
  "AV",
  "NCBC",
  "CBASP",
  "CCBC",
  "CC",
  "CBCS",
  "DOC",
  "CBES",
  "CBEVT",
  "CBG",
  "GOCBC",
  "CBHADOOP",
  "CBIT",
  "CBIDXT",
  "JCBC",
  "KAFKAC",
  "K8S",
  "CBL",
  "CMCR",
  "CMSR",
  "CM",
  "CBMON",
  "NGXCBM",
  "JSCBC",
  "CBPS",
  "PLCBC",
  "PCBC",
  "PYCBC",
  "CBQE",
  "RCBC",
  "SDKQE",
  "MB",
  "CBD",
  "CB",
  "SPARKC",
  "CBSS",
  "CBSP",
  "CBSE",
  "CBST",
  "CBUX",
  "DEVADV",
  "TXNN",
  "TXNCXX",
  "TXNG",
  "TXNJ",
  "COE",
  "FAC",
  "FORUM",
  "FEWD",
  "GC",
  "ICC",
  "JVMCBC",
  "JDCP",
  "KCBC",
  "LINQ",
  "PH",
  "PE",
  "QIS",
  "SAN",
  "SCBC",
  "SP",
  "SV",
  "SPY",
  "TALENDC",
];

function heading(project) {
  return (
    <div
      key={`heading-${project}`}
      style={{
        fontSize: 16,
        borderBottom: "1px",
        paddingBottom: "12px",
        fontWeight: "bold",
      }}
    >
      CHANGELOG for {project}:
    </div>
  );
}

export default function Changelog(props) {
  const log = props.log
  const [authorFilter, setAuthorFilter] = useState("")
  const [querystringFilters, setQuerystringFilters] = [
    props.querystringFilters,
    props.setQuerystringFilters,
  ];

  useEffect(() => {
    if (!authorFilter && querystringFilters["commit_author"]) {
      setAuthorFilter(querystringFilters["commit_author"]);
    }
  }, [querystringFilters["commit_author"]]);

  const setAuthor = (author) => {
    setAuthorFilter(author);
    props.setQuerystringFilters({
      ...querystringFilters,
      commit_author: author,
    });
  };

  useEffect(() => {
    if (log && log.changed) {
      Object.keys(log.changed)
        .sort()
        .map((project) => {
          querystringFilters[project] = querystringFilters[project] || "on";
          setQuerystringFilters({ ...querystringFilters });
          return querystringFilters[project];
        });
    }
  }, [log]);


  if (props.loading && props.loading.length > 0) {
    return (
      <Row id={props.id}>
        {props.loading && props.loading.length > 0 && (
          <Col id="LoadingSpinner">
            <div>
              <div style={{ textAlign: "center" }}>
                <Button variant="primary" disabled active={false}>
                  <Spinner
                    as="span"
                    animation="grow"
                    size="sm"
                    role="status"
                    aria-hidden="true"
                  />
                  &nbsp; Retrieving&nbsp;
                  {props.loading.join(", ")}
                </Button>
              </div>
            </div>
          </Col>
        )}
      </Row>
    );
  }


  const linkReviews = (text) => {
    if (Array.isArray(text)) {
      return text.map(t => linkReviews(t))
    } else if(typeof text === 'string') {
      gerritURLs.forEach((prefix) => {
        if (text.includes(`${prefix}/`)) {
          const textParts = text.split(new RegExp(`(${prefix}/[0-9]+\/*)`, "ig"));
          text = textParts.map((textPart, i) => {
            if (textPart.toLowerCase().startsWith(`${prefix.toLowerCase()}/`)) {
              return (
                <a key={textPart} href={textPart}>
                  {textPart}
                </a>
              );
            } else {
              return textPart;
            }
          });
        }
      });
      return text;
    }
    return text
  };

  const linkTickets = (text) => {
    jiraPrefixes.forEach((prefix) => {
      if (text.includes(`${prefix}-`)) {
        const textParts = text.split(new RegExp(`(${prefix}-[0-9]+)`, "ig"));
        text = textParts.map((textPart, i) => {
          if (textPart.toLowerCase().startsWith(`${prefix.toLowerCase()}-`)) {
            return (
              <a
                key={`${textPart}-${i}`}
                href={`https://issues.couchbase.com/browse/${textPart}`}
              >
                {textPart}
              </a>
            );
          } else {
            return textPart;
          }
        });
      }
    });
    return text;
  };

  const changed =
    log &&
    log.changed &&
    Object.keys(log.changed)
      .sort()
      .map((project) => {
        const commits = log.changed[project].added.filter((commit) =>
          commit.author.toLowerCase().includes(authorFilter.toLowerCase())
        );
        if (querystringFilters[project] === "on" && commits.length > 0) {
          return (
            <div key={project}>
              {heading(project)}
              {commits.map((commit) => {
                let summary = linkReviews(linkTickets(commit.summary));
                const sha = commit["key_"].split("-").slice(-1);
                const org = commit["remote"].split("/")[3];
                const url = `https://github.com/${org}/${project}/commit/${sha}`;
                const builds =
                  commit.in_build &&
                  commit.in_build
                    .map((ib) => {
                      if (ib.startsWith(`${props.product}-`)) {
                        let ver = ib.split("-").slice(-2, -1);
                        if (
                          ver >= props.fromVersion &&
                          ver <= props.toVersion
                        ) {
                          return `${props.product}-${ver}-${ib
                            .split("-")
                            .slice(-1)}`;
                        }
                      }
                    })
                    .filter((el) => el != null);

                return (
                  <div key={sha} style={{ paddingLeft: "20px" }}>
                    * Commit: <a href={url}>{sha}</a>{" "}
                    {builds && (
                      <span key={`${sha}-builds`}>
                        in build: <b>{builds.join(", ")}</b>
                      </span>
                    )}
                    <div key={`${sha}-inner`} style={{ paddingLeft: 32, paddingTop: 10 }}>
                      {summary}
                      <div key={`${sha}-author-${commit.author}`}>
                        Author: {commit.author}
                      </div>
                      <div key={`${sha}-committer-${commit.committer}`}>
                        Committer: {commit.committer}
                      </div>
                    </div>
                    <hr />
                  </div>
                );
              })}
            </div>
          );
        }
      })
      .filter((entries) => entries);

  const AuthorFilter = (p) => {
    return (
      <Input
        autoFocus
        type="text"
        name="author"
        id="commit_author"
        placeholder="Author"
        onChange={p.onChange}
        value={authorFilter}
      />
    );
  };

  return (
    <Row id={props.id}>
      {(log && (
        <>
          <Col sm="1.5" id="Filters">
            <AuthorFilter onChange={(e) => setAuthor(`${e.target.value}`)} />
            <ComponentFilters
              projects={Object.keys(log.changed).sort()}
              setQuerystringFilters={props.setQuerystringFilters}
              filters={querystringFilters}
            />
          </Col>
          <Col id="ChangeLog">
            <pre key="changelog">
              {(changed && changed.length === 0 && "No matching commits") ||
                changed}
            </pre>
          </Col>
        </>
      )) || <Col className="padded">{props.placeholder}</Col>}
    </Row>
  );
}

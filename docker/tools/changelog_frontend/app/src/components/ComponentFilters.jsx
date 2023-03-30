import React from "react";
import {
  Button,
  ButtonGroup,
  Card,
  Input,
  InputGroup,
  InputGroupAddon,
  InputGroupText,
  Row, Col
} from "reactstrap";

function toggleFilters(filters, state, setter) {
  Object.keys(filters).forEach((filter) => {
    // todo: handle this in a less obscure way
    if (filter !== "commit_author") filters[filter] = state;
  });
  setter({ ...filters });
}

function toggler(name, filters, state, setter) {
  return (
    <Button
      style={{ fontSize: "8pt", padding: "2px" }}
      key={`toggle_${state}`}
      onClick={() => {
        toggleFilters(filters, state, setter);
      }}
    >
      {name}
    </Button>
  );
}

export default function (props) {
  const selectAll = toggler(
    "all",
    props.filters,
    "on",
    props.setQuerystringFilters
  );

  const selectNone = toggler(
    "none",
    props.filters,
    "off",
    props.setQuerystringFilters
  );

  const selectors = (
    <ButtonGroup>
      {selectAll}
      {selectNone}
    </ButtonGroup>
  );

  return (
    <Card id="FilterCard">
      <Row style={{ paddingBottom:"8px"}}>
        <Col>
          <b>Projects</b>
        </Col>
        <Col>{selectors}</Col>
      </Row>
      {Object.keys(props.filters)
        .sort()
        .map((filter) => {
          if (filter !== "_" && props.projects.includes(filter))
            return (
              <InputGroup key={`ig${filter}`}>
                <InputGroupText>
                  <Input
                    id={filter}
                    addon
                    type="checkbox"
                    key={`igText${filter}`}
                    checked={props.filters[filter] === "on"}
                    onChange={() => {
                      props.filters[filter] =
                        props.filters[filter] === "on" ? "off" : "on";
                      props.setQuerystringFilters({
                        ...props.filters,
                      });
                    }}
                  />
                </InputGroupText>
                <InputGroupAddon  key={`igAppend${filter}`} addonType="append" style={{ width: "500" }}>
                  <InputGroupText key={`igAppendText${filter}`}>{filter}</InputGroupText>
                </InputGroupAddon>
              </InputGroup>
            );
        })}
    </Card>
  );
}
